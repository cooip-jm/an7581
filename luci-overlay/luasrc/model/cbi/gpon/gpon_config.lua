local sys = require "luci.sys"
local m, s, o

m = Map("xpon", translate("PON Configuration"),
    translate("Configure ONT identity and PON parameters for the Nokia XG-040G-MD (AN7581). " ..
              "The serial number is used for OLT authentication and is auto-generated from MAC if left empty."))

-- ─── Enable ─────────────────────────────────────────────
s = m:section(TypedSection, "ani", translate("PON Subsystem"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enable", translate("Enable PON"),
    translate("Start the PON driver stack, BOSA transceiver, and management daemons on boot."))
o.default = "1"
o.rmempty = false

-- ─── ONT Serial Number ──────────────────────────────────
s2 = m:section(TypedSection, "ani", translate("ONT Serial Number"),
    translate("12-character serial number: 4-char vendor ID + 8-char VSSN. " ..
              "Auto-generated from MAC address if left empty."))
s2.anonymous = true
s2.addremove = false

o = s2:option(Value, "serial_number", translate("Serial Number"),
    translate("Exactly 12 characters. Vendor ID (first 4) identifies the manufacturer."))
o.datatype = "maxlength(12)"
o.rmempty = true
o.placeholder = "Auto-generated from MAC"

-- ─── PLOAM Password ─────────────────────────────────────
s3 = m:section(TypedSection, "ani", translate("PLOAM Password"),
    translate("PLOAM (Physical Layer OAM) authentication password for GPON/XGS-PON."))
s3.anonymous = true
s3.addremove = false

o = s3:option(Value, "ploam_password", translate("Password"),
    translate("ASCII: max 10 characters. HEX: max 20 hex digits (0-9, A-F)."))
o.datatype = "maxlength(20)"
o.rmempty = true
o.password = true

o = s3:option(ListValue, "ploam_hexadecimalpassword", translate("Password Format"))
o:value("0", translate("ASCII"))
o:value("1", translate("HEX"))
o.default = "0"
o.rmempty = false

-- ─── Equipment ID ───────────────────────────────────────
s4 = m:section(TypedSection, "ani", translate("Equipment ID"),
    translate("ONT Equipment ID reported to the OLT via OMCI."))
s4.anonymous = true
s4.addremove = false

o = s4:option(Value, "equipment_id", translate("Equipment ID"))
o.datatype = "maxlength(20)"
o.rmempty = true
o.placeholder = "Auto from profile.cfg"

-- ─── LOID Authentication ────────────────────────────────
s5 = m:section(TypedSection, "ani", translate("LOID Authentication"),
    translate("Logical ID for CTC (China Telecom/Unicom/Mobile) OLT registration."))
s5.anonymous = true
s5.addremove = false

o = s5:option(Value, "loid", translate("Logical ID"))
o.datatype = "maxlength(24)"
o.rmempty = true

o = s5:option(Value, "loid_password", translate("LOID Password"))
o.datatype = "maxlength(12)"
o.rmempty = true
o.password = true

-- ─── ONU Version ────────────────────────────────────────
s6 = m:section(TypedSection, "ani", translate("ONU Version"),
    translate("ONU version string reported via OMCI. Leave empty for auto-detect."))
s6.anonymous = true
s6.addremove = false

o = s6:option(Value, "onu_version", translate("ONU Version"))
o.rmempty = true

-- ─── Apply ──────────────────────────────────────────────
m.on_after_commit = function(self)
    sys.call("/etc/init.d/xpon restart &")
    sys.call("logger -t luci-gpon 'PON configuration applied'")
end

return m
