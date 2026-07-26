local sys = require "luci.sys"
local m, s, o

m = Map("pon_auth", translate("OLT Authentication"),
    translate("Configure ONT serial number and password for OLT authentication. " ..
              "Changes require PON link re-establishment to take effect."))

-- ─── SLID (Serial Number / Password) ───────────────────
s = m:section(TypedSection, "slid", translate("SLID / Password Authentication"),
    translate("Set the ONT password (SLID) used for password-based OLT authentication."))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("Enable Password Authentication"))
o.default = "0"
o.rmempty = false

o = s:option(Value, "value", translate("ONT Password (SLID)"),
    translate("Password for OLT authentication. ASCII: max 10 characters. " ..
              "HEX: max 20 hex characters (0-9, A-F)."))
o.datatype = "maxlength(20)"
o.rmempty = true
o.password = true

o = s:option(ListValue, "mode", translate("SLID Format"))
o:value("ascii", translate("ASCII Mode (max 10 characters)"))
o:value("hex", translate("HEX Mode (max 20 hex digits)"))
o.default = "ascii"
o.rmempty = false

-- ─── LOID (Logical ID) ─────────────────────────────────
s2 = m:section(TypedSection, "loid", translate("LOID / Logical ID Authentication"),
    translate("Set the Logical ID for CTC (China Telecom/Unicom/Mobile) registration."))
s2.anonymous = true
s2.addremove = false

o = s2:option(Flag, "enabled", translate("Enable LOID Authentication"))
o.default = "0"
o.rmempty = false

o = s2:option(Value, "value", translate("Logical ID"),
    translate("Logic Identifier for OLT registration. Max 24 characters."))
o.datatype = "maxlength(24)"
o.rmempty = true

o = s2:option(Value, "password", translate("LOID Password"),
    translate("Password associated with the Logical ID. Max 12 characters."))
o.datatype = "maxlength(12)"
o.rmempty = true
o.password = true

-- ─── Password Auth ──────────────────────────────────────
s3 = m:section(TypedSection, "password", translate("Direct Password Authentication"),
    translate("Set a direct ONT password (used by some OLTs that require password-only auth)."))
s3.anonymous = true
s3.addremove = false

o = s3:option(Value, "value", translate("ONT Password"))
o.datatype = "maxlength(20)"
o.rmempty = true
o.password = true

-- ─── Apply callback ─────────────────────────────────────
m.on_after_commit = function(self)
    sys.call("/usr/libexec/pon_apply_uci.sh &")
    luci.util.exec("logger -t luci-gpon 'PON authentication configuration applied'")
end

return m
