#!/bin/sh

ETHPHXCMD=""

[ -x "/userfs/bin/ethphxcmd" ] && ETHPHXCMD="/userfs/bin/ethphxcmd"
[ -x "/usr/bin/ethphxcmd" ] && ETHPHXCMD="/usr/bin/ethphxcmd"
[ -z "${ETHPHXCMD}" ] && exit 1

${ETHPHXCMD} gsww 200c 10
${ETHPHXCMD} gsww 210c 10
${ETHPHXCMD} gsww 220c 10
${ETHPHXCMD} gsww 230c 10
${ETHPHXCMD} gsww 240c 10
${ETHPHXCMD} gsww 260c 10
${ETHPHXCMD} arl mactbl-clr
