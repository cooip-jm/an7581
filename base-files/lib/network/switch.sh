#!/bin/sh

. /lib/functions.sh

WANDEV=
LANDEVS=
ETH_PORTMAP_FILE="/proc/tc3162/eth_portmap"

tc3162_eth_portmap() {
	local wan_port="-1"
	local portmap port i

	case "$WANDEV" in
		eth0.[0-9])
			wan_port=${WANDEV:5}
		;;
	esac

	portmap="${wan_port}"
	for i in $(seq 1 6); do
		port="-1"
		if [ "${i}" -ne "${wan_port}" ]; then
			echo $LANDEVS | tr ' ' '\n' | grep -qxF "eth0.${i}" && port=$i
		fi
		portmap="${portmap} ${port}"
	done

	echo "${portmap}" > "$ETH_PORTMAP_FILE"
}

assign_to_lan() {
	local ifname="$1"

	[ "${ifname:0:5}" = "eth0." ] || return 0
	[ -d "/sys/class/net/$ifname" ] || return 0

	LANDEVS="$LANDEVS $ifname"
}

setup_switch() {
	[ -x /userfs/bin/switchmgr ] && /userfs/bin/switchmgr vlanactive 1

	[ -f /etc/board.json ] || return 0
	[ -w "$ETH_PORTMAP_FILE" ] || return 0

	# if wan part of eth_portmap is already configured (is not -1)
	# assume that board specific port mapping was done in a previous stage
	[ "$(head -n 1 "$ETH_PORTMAP_FILE")" = "-1" ]  || return 0

	WANDEV="$(jsonfilter -i /etc/board.json -e @.network.wan.device)"
	json_init
	json_load_file /etc/board.json
	json_select network
	json_select lan
	if json_is_a ports array; then
		json_for_each_item "assign_to_lan" "ports"
	else
		json_get_var lan_device device
		[ -n "$lan_device" ] && assign_to_lan "$lan_device"
	fi
	json_select ..
	json_cleanup

	[ -n "$WANDEV" -o -n "$LANDEVS" ] && tc3162_eth_portmap
}
