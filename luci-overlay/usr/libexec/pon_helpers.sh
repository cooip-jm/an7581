#!/bin/sh
# PON helper functions for LuCI integration on AN7581
# Wraps vendor CLI tools: ponmgr, omcli, hcfgtool, ritool
# Per LUCI_PON_DESIGN.md

export LD_LIBRARY_PATH="/usr/lib:${LD_LIBRARY_PATH}"
PONMGR="/sbin/ponmgr"
OMCLI="/sbin/omciMgr"
HCFGTOOL="/usr/bin/hcfgtool"
RITOOL="/usr/bin/ritool"

# ─── Hardware Info ───────────────────────────────────────

pon_get_board_id() {
    $RITOOL get BoardID 2>/dev/null | awk -F ':' '{print $2}' | tr -d ' '
}

pon_get_part_number() {
    $RITOOL get PartNumber 2>/dev/null | awk -F ':' '{print $2}' | tr -d ' '
}

pon_get_operator_id() {
    $RITOOL get OperatorID 2>/dev/null | grep OperatorID | awk '{print substr($2,12)}'
}

pon_get_bosa_chip() {
    $HCFGTOOL get Bosa.Chip.Name 2>/dev/null
}

pon_get_tx_disable_pin() {
    $HCFGTOOL get Pon.TxDisable.Pin 2>/dev/null
}

pon_get_tx_enable_pin() {
    $HCFGTOOL get Pon.TxPowerEnable.Pin 2>/dev/null
}

# ─── PON Manager Commands ────────────────────────────────

pon_get_status() {
    $PONMGR gpon get status 2>/dev/null
}

pon_get_link_status() {
    $PONMGR gpon get sys_link_cfg 2>/dev/null
}

pon_set_link_cfg() {
    local val="$1"
    $PONMGR gpon set sys_link_cfg "$val" 2>/dev/null
}

pon_get_fec_cfg() {
    $PONMGR gpon get rx_fec_cfg 2>/dev/null
}

pon_set_fec_cfg() {
    local val="$1"
    $PONMGR gpon set rx_fec_cfg "$val" 2>/dev/null
}

pon_set_dbg_level() {
    local val="$1"  # enable|disable
    $PONMGR gpon set dbg_level "$val" 2>/dev/null
}

pon_set_init_report() {
    local val="$1"  # 0|1
    $PONMGR gpon set event_ctrl init_report_o1 "$val" 2>/dev/null
}

# ─── SLID / Password ─────────────────────────────────────

pon_set_slid() {
    local value="$1"
    local mode="$2"  # ascii|hex

    if [ "$mode" = "hex" ]; then
        echo "$value" | grep -qE '^[0-9a-fA-F]{0,20}$' || return 1
    else
        [ ${#value} -le 10 ] || return 1
    fi

    $PONMGR gpon set ont_password "$value" 2>/dev/null
}

# ─── LOID ────────────────────────────────────────────────

pon_set_loid() {
    local loid="$1"
    local password="$2"

    [ ${#loid} -le 24 ] || return 1
    [ ${#password} -le 12 ] || return 1

    $OMCLI setLoid "$loid" "$password" 2>/dev/null
}

# ─── Optical Module (from proc) ──────────────────────────

pon_get_tx_power_raw() { cat /proc/tc3162/pon_txpower 2>/dev/null; }
pon_get_rx_power_raw() { cat /proc/tc3162/pon_rxpower 2>/dev/null; }
pon_get_temperature_raw() { cat /proc/tc3162/pon_temp 2>/dev/null; }
pon_get_bias_current_raw() { cat /proc/tc3162/pon_bias 2>/dev/null; }
pon_get_voltage_raw() { cat /proc/tc3162/pon_voltage 2>/dev/null; }

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

# ─── OMCI ────────────────────────────────────────────────

omci_set_pm_flag() {
    local val="$1"
    $OMCLI setPmFlag "$val" 2>/dev/null
}

# ─── Process Status ──────────────────────────────────────

pon_omcimgr_running() { pidof omciMgr >/dev/null 2>&1; }
pon_ponmgr_running()  { pidof ponmgr >/dev/null 2>&1; }

# ─── Full Status JSON ────────────────────────────────────

pon_get_full_status() {
    local status_raw=$(pon_get_status)
    local fec_raw=$(pon_get_fec_cfg)

    local pon_state="Unknown"
    local link_state="Down"
    local fec=0

    case "$status_raw" in
        *Up*)           pon_state="Up"; link_state="Connected" ;;
        *Initializing*) pon_state="Initializing"; link_state="Not connected" ;;
        *EstablishingLink*) pon_state="EstablishingLink"; link_state="Not connected" ;;
        *NoSignal*)     pon_state="NoSignal"; link_state="No signal" ;;
        *LowSignalPower*) pon_state="LowSignalPower"; link_state="Low signal" ;;
    esac

    case "$fec_raw" in
        *1*|*enable*) fec=1 ;;
        *) fec=0 ;;
    esac

    cat <<EOF
{
    "link_state": "$link_state",
    "pon_state": "$pon_state",
    "fec_rx": $fec,
    "tx_power": "$(pon_get_tx_power_dbm)",
    "rx_power": "$(pon_get_rx_power_dbm)",
    "temperature": "$(pon_get_temperature)",
    "bias_current": "$(pon_get_bias_current)",
    "voltage": "$(pon_get_voltage)",
    "omcimgr_running": $(pon_omcimgr_running && echo 1 || echo 0),
    "ponmgr_running": $(pon_ponmgr_running && echo 1 || echo 0)
}
EOF
}

# ─── Apply UCI Config ────────────────────────────────────

pon_apply_config() {
    local fec_rx=$(uci get pon.global.fec_rx 2>/dev/null)
    local fec_tx=$(uci get pon.global.fec_tx 2>/dev/null)
    local debug=$(uci get pon.global.event_debug 2>/dev/null)
    local init_rpt=$(uci get pon.global.init_report 2>/dev/null)
    local slid_val=$(uci get pon_auth.slid.value 2>/dev/null)
    local slid_mode=$(uci get pon_auth.slid.mode 2>/dev/null)

    [ -n "$fec_rx" ] && pon_set_fec_cfg "$fec_rx"
    [ -n "$debug" ] && {
        [ "$debug" = "1" ] && pon_set_dbg_level enable || pon_set_dbg_level disable
    }
    [ -n "$init_rpt" ] && pon_set_init_report "$init_rpt"
    [ -n "$slid_val" ] && pon_set_slid "$slid_val" "${slid_mode:-ascii}"
}
