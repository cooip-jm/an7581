#!/bin/sh
# PON helper functions for LuCI integration on AN7581
# Wraps vendor CLI tools to match IOPSYS ponmngr architecture
# Key tool: omcicfgCmd (part of omci/bbf247 package)

export LD_LIBRARY_PATH="/usr/lib:/usr/lib64:${LD_LIBRARY_PATH}"

# ─── OMCI Configuration Commands ────────────────────────
# These are the PRIMARY way to set ONT identity parameters
# omcicfgCmd talks to the running omci daemon

omcicfgCmd() {
    # Try /userfs first (IOPSYS standard), then /usr/bin, then /sbin
    for bin in /userfs/bin/omcicfgCmd /usr/bin/omcicfgCmd /sbin/omcicfgCmd; do
        [ -x "$bin" ] && "$bin" "$@" && return $?
    done
    # Fallback: the vendor omci binary may have omcicfgCmd as subcommand
    for bin in /userfs/bin/omci /usr/bin/omci /sbin/omci; do
        [ -x "$bin" ] && "$bin" omcicfgCmd "$@" && return $?
    done
    logger -t pon-helpers "ERROR: omcicfgCmd not found"
    return 1
}

# ─── Serial Number ──────────────────────────────────────

set_serial_number() {
    local vendor_id="$1"
    local vssn="$2"
    [ -z "$vendor_id" ] && return 1
    [ -z "$vssn" ] && return 1
    omcicfgCmd set vendorId "${vendor_id}"
    omcicfgCmd set sn "${vendor_id}${vssn}"
}

get_serial_number() {
    uci -q get xpon.ani.serial_number 2>/dev/null
}

# ─── PLOAM Password ─────────────────────────────────────

set_ploam_password() {
    local passwd="$1"
    local hex="$2"
    [ -z "$passwd" ] && return 1
    if [ -z "$hex" -o "$hex" = "0" ]; then
        omcicfgCmd set passwdAscii "${passwd}"
    else
        omcicfgCmd set passwdHex "${passwd}"
    fi
}

# ─── Equipment ID ───────────────────────────────────────

set_equipment_id() {
    local eqid="$1"
    [ -z "${eqid}" ] && return 0
    omcicfgCmd set equipmentId "${eqid}"
}

# ─── LOID Authentication ────────────────────────────────

set_loid_authentication() {
    local loid="$1"
    local loid_pwd="$2"
    [ -z "${loid}" ] && return 0
    omcicfgCmd set loid "${loid}"
    [ -n "${loid_pwd}" ] && omcicfgCmd set loidPasswd "${loid_pwd}"
}

# ─── ONU Version ────────────────────────────────────────

set_onu_version() {
    local onu_version="$1"
    [ -z "${onu_version}" ] && return 0
    omcicfgCmd set onuVersion "${onu_version}"
}

# ─── Hardware Info (via ritool/hcfgtool) ────────────────

pon_get_board_id() {
    ritool get BoardID 2>/dev/null
}

pon_get_part_number() {
    ritool get PartNumber 2>/dev/null
}

pon_get_bosa_chip() {
    hcfgtool get Bosa.Chip.Name 2>/dev/null
}

# ─── Optical Module (from proc) ─────────────────────────

pon_get_tx_power_raw() {
    cat /proc/tc3162/pon_txpower 2>/dev/null
}

pon_get_rx_power_raw() {
    cat /proc/tc3162/pon_rxpower 2>/dev/null
}

pon_get_temperature_raw() {
    cat /proc/tc3162/pon_temp 2>/dev/null
}

pon_get_bias_current_raw() {
    cat /proc/tc3162/pon_bias 2>/dev/null
}

pon_get_voltage_raw() {
    cat /proc/tc3162/pon_voltage 2>/dev/null
}

pon_raw_to_dbm() {
    local raw="$1"
    if [ -n "$raw" ] && [ "$raw" -gt 0 ] 2>/dev/null; then
        local int_part=$((raw / 1000))
        local frac_part=$((raw % 1000))
        printf "%d.%03d" "$int_part" "$frac_part"
    else
        echo "N/A"
    fi
}

pon_get_tx_power_dbm() { pon_raw_to_dbm "$(pon_get_tx_power_raw)"; }
pon_get_rx_power_dbm() { pon_raw_to_dbm "$(pon_get_rx_power_raw)"; }

pon_get_temperature() {
    local raw=$(pon_get_temperature_raw)
    if [ -n "$raw" ] && [ "$raw" -gt 0 ] 2>/dev/null; then
        local int_part=$((raw / 256))
        local frac_part=$(( (raw % 256) * 100 / 256 ))
        printf "%d.%02d" "$int_part" "$frac_part"
    else
        echo "N/A"
    fi
}

pon_get_bias_current() {
    local raw=$(pon_get_bias_current_raw)
    [ -n "$raw" ] && [ "$raw" -gt 0 ] 2>/dev/null && echo "$((raw * 2))" || echo "N/A"
}

pon_get_voltage() {
    local raw=$(pon_get_voltage_raw)
    [ -n "$raw" ] && [ "$raw" -gt 0 ] 2>/dev/null && echo "$((raw * 100))" || echo "N/A"
}

pon_get_tx_packets() { cat /proc/tc3162/pon_txpkts 2>/dev/null || echo "0"; }
pon_get_rx_packets() { cat /proc/tc3162/pon_rxpkts 2>/dev/null || echo "0"; }
pon_get_tx_bytes()   { cat /proc/tc3162/pon_txbytes 2>/dev/null || echo "0"; }
pon_get_rx_bytes()   { cat /proc/tc3162/pon_rxbytes 2>/dev/null || echo "0"; }

# ─── PON Status ─────────────────────────────────────────

pon_get_status() {
    cat /proc/tc3162/pon_state 2>/dev/null || \
    cat /sys/class/ont/state 2>/dev/null || \
    echo "Unknown"
}

pon_omcimgr_running() { pidof omci >/dev/null 2>&1 || pidof omciMgr >/dev/null 2>&1; }
pon_ponmgr_running()  { pidof ponmgr_cfg >/dev/null 2>&1 || pidof ponmgr >/dev/null 2>&1; }

# ─── Apply UCI xpon.ani config to running daemons ───────

pon_apply_uci_config() {
    [ "$(uci -q get xpon.ani.enable)" = "1" ] || return

    # Serial number
    local serial_number="$(uci -q get xpon.ani.serial_number)"
    if [ ${#serial_number} -eq 12 ]; then
        local vendor_id="${serial_number:0:4}"
        local vssn="${serial_number:4:8}"
        set_serial_number "$vendor_id" "$vssn"
    fi

    # PLOAM password
    local passwd="$(uci -q get xpon.ani.ploam_password)"
    local hex="$(uci -q get xpon.ani.ploam_hexadecimalpassword)"
    [ -n "$passwd" ] && set_ploam_password "$passwd" "$hex"

    # Equipment ID
    local eqid="$(uci -q get xpon.ani.equipment_id)"
    set_equipment_id "$eqid"

    # LOID
    local loid="$(uci -q get xpon.ani.loid)"
    local loid_pwd="$(uci -q get xpon.ani.loid_password)"
    set_loid_authentication "$loid" "$loid_pwd"

    # ONU version
    local onu_version="$(uci -q get xpon.ani.onu_version)"
    set_onu_version "$onu_version"

    logger -t pon-helpers "UCI xpon.ani configuration applied"
}
