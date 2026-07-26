#!/bin/sh
# Apply UCI pon config to running PON daemons
# Called by ecnt_xpon after daemons start, or by LuCI on config save
# Per LUCI_PON_DESIGN.md

export LD_LIBRARY_PATH="/usr/lib:${LD_LIBRARY_PATH}"

[ -f /usr/libexec/pon_helpers.sh ] || {
    logger -t airoha-pon "pon_helpers.sh not found, skipping UCI apply"
    exit 1
}

. /usr/libexec/pon_helpers.sh

# Wait for ponmgr to be ready (up to 10 seconds)
wait_ponmgr=0
while ! pon_ponmgr_running && [ $wait_ponmgr -lt 10 ]; do
    sleep 1
    wait_ponmgr=$((wait_ponmgr + 1))
done

if ! pon_ponmgr_running; then
    logger -t airoha-pon "ponmgr not running, cannot apply UCI config"
    exit 1
fi

# Apply FEC settings
fec_rx=$(uci get pon.global.fec_rx 2>/dev/null)
[ -n "$fec_rx" ] && {
    pon_set_fec_cfg "$fec_rx"
    logger -t airoha-pon "Applied FEC RX: $fec_rx"
}

# Apply debug level
debug=$(uci get pon.global.event_debug 2>/dev/null)
if [ "$debug" = "1" ]; then
    pon_set_dbg_level enable
else
    pon_set_dbg_level disable
fi

# Apply init_report_o1
init_rpt=$(uci get pon.global.init_report 2>/dev/null)
[ -n "$init_rpt" ] && pon_set_init_report "$init_rpt"

# Apply SLID/password
slid_val=$(uci get pon_auth.slid.value 2>/dev/null)
slid_mode=$(uci get pon_auth.slid.mode 2>/dev/null)
slid_en=$(uci get pon_auth.slid.enabled 2>/dev/null)
if [ "$slid_en" = "1" ] && [ -n "$slid_val" ]; then
    pon_set_slid "$slid_val" "${slid_mode:-ascii}"
    logger -t airoha-pon "Applied SLID (mode=${slid_mode:-ascii})"
fi

# Apply LOID
loid_val=$(uci get pon_auth.loid.value 2>/dev/null)
loid_pwd=$(uci get pon_auth.loid.password 2>/dev/null)
loid_en=$(uci get pon_auth.loid.enabled 2>/dev/null)
if [ "$loid_en" = "1" ] && [ -n "$loid_val" ]; then
    pon_set_loid "$loid_val" "$loid_pwd"
    logger -t airoha-pon "Applied LOID authentication"
fi

# Apply OMCI PM flag
pm_flag=$(uci get pon.omci.pm_flag 2>/dev/null)
[ -n "$pm_flag" ] && omci_set_pm_flag "$pm_flag"

logger -t airoha-pon "UCI configuration applied successfully"
