#!/bin/sh
# Apply UCI xpon.ani config to running PON daemons
# Called by xpon init.d or by LuCI on config save

export LD_LIBRARY_PATH="/usr/lib:/usr/lib64:${LD_LIBRARY_PATH}"

[ -f /usr/libexec/pon_helpers.sh ] || {
    logger -t pon-apply "pon_helpers.sh not found, skipping UCI apply"
    exit 1
}

. /usr/libexec/pon_helpers.sh

pon_apply_uci_config

logger -t pon-apply "UCI configuration applied successfully"
