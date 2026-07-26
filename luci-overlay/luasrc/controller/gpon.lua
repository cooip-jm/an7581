module("luci.controller.gpon", package.seeall)

HELPERS = "/usr/libexec/pon_helpers.sh"

function index()
    entry({"admin", "network", "gpon"}, alias("admin", "network", "gpon", "status"),
          _("PON Management"), 60)

    entry({"admin", "network", "gpon", "status"}, template("gpon/status"),
          _("PON Status"), 10).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "config"}, cbi("gpon/gpon_config"),
          _("PON Configuration"), 20).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "optical"}, template("gpon/optical"),
          _("Optical Module"), 30).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "omci"}, template("gpon/omci"),
          _("OMCI Status"), 40).depends("admin/network/gpon")

    -- AJAX API endpoints
    entry({"admin", "network", "gpon", "api", "status"}, call("action_api_status"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "optical"}, call("action_api_optical"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "omci"}, call("action_api_omci"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "apply"}, call("action_api_apply"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "restart"}, call("action_api_restart"), nil)
        .leaf = true
end

local function helpers_run(func)
    local sys = require "luci.sys"
    local result = sys.exec(". " .. HELPERS .. " 2>/dev/null; " .. func)
    if result then
        result = result:gsub("%s+$", ""):gsub("^%s+", "")
    end
    return result
end

function action_api_status()
    local sys = require "luci.sys"

    local status = {}

    status.pon_state = helpers_run("pon_get_status") or "Unknown"

    local fec = helpers_run("pon_get_fec_cfg")
    status.fec_rx = (fec and fec:match("1") or fec:match("enable")) and 1 or 0

    status.tx_power = helpers_run("pon_get_tx_power_dbm") or "N/A"
    status.rx_power = helpers_run("pon_get_rx_power_dbm") or "N/A"
    status.temperature = helpers_run("pon_get_temperature") or "N/A"
    status.bias_current = helpers_run("pon_get_bias_current") or "N/A"
    status.voltage = helpers_run("pon_get_voltage") or "N/A"

    status.omcimgr_running = sys.call("pidof omci >/dev/null 2>&1") == 0 or
                             sys.call("pidof omciMgr >/dev/null 2>&1") == 0
    status.ponmgr_running = sys.call("pidof ponmgr_cfg >/dev/null 2>&1") == 0 or
                            sys.call("pidof ponmgr >/dev/null 2>&1") == 0

    status.fec_rx_cfg = sys.exec("uci get xpon.ani.enable 2>/dev/null | tr -d '\\n'") or "1"

    status.tx_packets = helpers_run("pon_get_tx_packets") or "0"
    status.rx_packets = helpers_run("pon_get_rx_packets") or "0"
    status.tx_bytes = helpers_run("pon_get_tx_bytes") or "0"
    status.rx_bytes = helpers_run("pon_get_rx_bytes") or "0"

    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end

function action_api_optical()
    local optical = {}

    optical.tx_power = helpers_run("pon_get_tx_power_dbm") or "N/A"
    optical.rx_power = helpers_run("pon_get_rx_power_dbm") or "N/A"
    optical.temperature = helpers_run("pon_get_temperature") or "N/A"
    optical.bias_current = helpers_run("pon_get_bias_current") or "N/A"
    optical.voltage = helpers_run("pon_get_voltage") or "N/A"

    optical.tx_packets = helpers_run("pon_get_tx_packets") or "0"
    optical.rx_packets = helpers_run("pon_get_rx_packets") or "0"
    optical.tx_bytes = helpers_run("pon_get_tx_bytes") or "0"
    optical.rx_bytes = helpers_run("pon_get_rx_bytes") or "0"

    luci.http.prepare_content("application/json")
    luci.http.write_json(optical)
end

function action_api_omci()
    local sys = require "luci.sys"
    local info = {}

    info.state = helpers_run("pon_get_status") or "unknown"
    info.sn = sys.exec("uci -q get xpon.ani.serial_number 2>/dev/null | tr -d '\\n'") or ""
    info.eqid = sys.exec("uci -q get xpon.ani.equipment_id 2>/dev/null | tr -d '\\n'") or ""
    info.omcimgr_running = sys.call("pidof omci >/dev/null 2>&1") == 0 or
                           sys.call("pidof omciMgr >/dev/null 2>&1") == 0

    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

function action_api_apply()
    local json = require "luci.jsonc"
    local sys = require "luci.sys"

    local raw = luci.http.content()
    local params = json.parse(raw) or {}

    if params.serial_number then
        sys.call(string.format(
            "uci set xpon.ani.serial_number='%s' && uci commit xpon",
            params.serial_number))
    end

    if params.ploam_password then
        local hex = params.ploam_hexadecimalpassword or "0"
        sys.call(string.format(
            "uci set xpon.ani.ploam_password='%s' && uci set xpon.ani.ploam_hexadecimalpassword='%s' && uci commit xpon",
            params.ploam_password, hex))
    end

    if params.equipment_id then
        sys.call(string.format(
            "uci set xpon.ani.equipment_id='%s' && uci commit xpon",
            params.equipment_id))
    end

    if params.loid then
        sys.call(string.format(
            "uci set xpon.ani.loid='%s' && uci commit xpon",
            params.loid))
    end

    if params.loid_password then
        sys.call(string.format(
            "uci set xpon.ani.loid_password='%s' && uci commit xpon",
            params.loid_password))
    end

    -- Restart xpon service to apply changes
    sys.call("/etc/init.d/xpon restart &")

    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true })
end

function action_api_restart()
    local sys = require "luci.sys"
    local service = luci.http.formvalue("service")

    if service == "omcimgr" then
        sys.call("/etc/init.d/xpon restart &")
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = true, service = "xpon" })
    elseif service == "ponmgr" then
        sys.call("/etc/init.d/xpon restart &")
        luci.http.prepare_content("application/json")
        luci.http.write_json({ success = true, service = "xpon" })
    else
        luci.http.status(400)
        luci.http.prepare_content("application/json")
        luci.http.write_json({ error = "unknown service" })
    end
end
