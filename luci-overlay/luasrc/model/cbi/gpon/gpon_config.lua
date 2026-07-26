local sys = require "luci.sys"
local m, s, o

m = Map("pon", translate("PON Configuration"),
    translate("Configure PON hardware parameters for the Nokia XG-040G-MD (AN7581). " ..
              "Changes are applied to the running PON daemons upon save."))

-- ─── Global Settings ────────────────────────────────────
s = m:section(TypedSection, "global", translate("Global Settings"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("Enable PON Subsystem"),
    translate("Start the PON driver stack, BOSA transceiver, and management daemons on boot."))
o.default = "1"
o.rmempty = false

o = s:option(ListValue, "pon_mode", translate("PON Mode"),
    translate("Select the PON protocol. Auto-detect is recommended."))
o:value("auto", translate("Auto-detect"))
o:value("gpon", translate("GPON (ITU-T G.984)"))
o:value("epon", translate("EPON (IEEE 802.3ah)"))
o:value("xgspon", translate("XGS-PON (ITU-T G.9807.1)"))
o.default = "auto"
o.rmempty = false
o.readonly = true

o = s:option(ListValue, "bosa_chip", translate("BOSA Transceiver Chip"),
    translate("Optical transceiver chip type. EN7572 is the Nokia XG-040G-MD internal chip."))
o:value("en7572", translate("EN7572 (internal)"))
o:value("gn25l98", translate("GN25L98"))
o:value("gn28l96", translate("GN28L96"))
o:value("ux3320", translate("UX3320"))
o:value("mtk", translate("MTK"))
o.default = "en7572"
o.rmempty = false
o.readonly = true

-- ─── FEC Settings ───────────────────────────────────────
s2 = m:section(TypedSection, "global", translate("FEC Settings"),
    translate("Forward Error Correction affects signal quality and throughput."))
s2.anonymous = true
s2.addremove = false

o = s2:option(Flag, "fec_rx", translate("RX FEC (Downstream)"),
    translate("Enable Forward Error Correction for downstream (OLT→ONT) frames."))
o.default = "1"
o.rmempty = false

o = s2:option(Flag, "fec_tx", translate("TX FEC (Upstream)"),
    translate("Enable Forward Error Correction for upstream (ONT→OLT) frames."))
o.default = "1"
o.rmempty = false

-- ─── Debug ──────────────────────────────────────────────
s3 = m:section(TypedSection, "global", translate("Diagnostics"))
s3.anonymous = true
s3.addremove = false

o = s3:option(Flag, "event_debug", translate("Enable PON Debug Logging"),
    translate("Enables detailed PON event logging via ponmgr."))
o.default = "0"
o.rmempty = false

o = s3:option(Flag, "init_report", translate("Enable O1 Init Report"),
    translate("Report O1 initialization events to the OLT."))
o.default = "1"
o.rmempty = false

-- ─── OMCI Settings ──────────────────────────────────────
s4 = m:section(TypedSection, "omci", translate("OMCI Settings"))
s4.anonymous = true
s4.addremove = false

o = s4:option(Flag, "enabled", translate("Enable OMCI Manager"),
    translate("Enable OMCI (ONU Management and Control Interface) management."))
o.default = "1"
o.rmempty = false

o = s4:option(ListValue, "pm_flag", translate("Performance Monitor"),
    translate("OMCI performance monitoring."))
o:value("0", translate("Disabled"))
o:value("1", translate("Enabled"))
o.default = "0"
o.rmempty = false

-- ─── PON VLAN ───────────────────────────────────────────
s5 = m:section(TypedSection, "pon_vlan", translate("PON VLAN"))
s5.anonymous = true
s5.addremove = false

o = s5:option(Flag, "enabled", translate("Enable PON VLAN"))
o.default = "0"
o.rmempty = false

o = s5:option(ListValue, "mode", translate("VLAN Mode"))
o:value("tag", translate("Tag"))
o:value("transparent", translate("Transparent"))
o:value("translate", translate("Translate"))
o.default = "tag"
o.rmempty = false

-- ─── Apply callback ─────────────────────────────────────
m.on_after_commit = function(self)
    sys.call(". /usr/libexec/pon_helpers.sh && pon_apply_config &")
    luci.util.exec("logger -t luci-gpon 'PON configuration applied'")
end

return m
