module("luci.controller.gpon", package.seeall)

HELPERS = "/usr/libexec/pon_helpers.sh"

function index()
    entry({"admin", "network", "gpon"}, alias("admin", "network", "gpon", "status"),
          _("PON Management"), 60)

    entry({"admin", "network", "gpon", "status"}, template("gpon/status"),
          _("PON Status"), 10).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "config"}, cbi("gpon/gpon_config"),
          _("PON Configuration"), 20).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "auth"}, cbi("gpon/gpon_auth"),
          _("OLT Authentication"), 30).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "optical"}, template("gpon/optical"),
          _("Optical Module"), 40).depends("admin/network/gpon")

    entry({"admin", "network", "gpon", "omci"}, template("gpon/omci"),
          _("OMCI Status"), 50).depends("admin/network/gpon")

    -- AJAX API endpoints
    entry({"admin", "network", "gpon", "api", "status"}, call("action_api_status"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "optical"}, call("action_api_optical"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "omci"}, call("action_api_omci"), nil)
        .leaf = true
    entry({"admin", "network", "gpon", "api", "apply"}, call("action_api_apply"), nil)
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
    local json = require "luci.jsonc"
    local sys = require "luci.sys"

    local status = {}

    status.pon_state = helpers_run("pon_get_status") or "Unknown"
    status.link_state = helpers_run("pon_get_link_status") or "Down"

    local fec = helpers_run("pon_get_fec_cfg")
    status.fec_rx = (fec and fec:match("1") or fec:match("enable")) and 1 or 0

    status.tx_power = helpers_run("pon_get_tx_power_dbm") or "N/A"
    status.rx_power = helpers_run("pon_get_rx_power_dbm") or "N/A"
    status.temperature = helpers_run("pon_get_temperature") or "N/A"
    status.bias_current = helpers_run("pon_get_bias_current") or "N/A"
    status.voltage = helpers_run("pon_get_voltage") or "N/A"

    status.omcimgr_running = sys.call("pidof omciMgr >/dev/null 2>&1") == 0
    status.ponmgr_running = sys.call("pidof ponmgr >/dev/null 2>&1") == 0

    status.fec_rx_cfg = sys.exec("uci get pon.global.fec_rx 2>/dev/null | tr -d '\\n'") or "1"
    status.fec_tx_cfg = sys.exec("uci get pon.global.fec_tx 2>/dev/null | tr -d '\\n'") or "1"
    status.pon_mode = sys.exec("uci get pon.global.pon_mode 2>/dev/null | tr -d '\\n'") or "auto"
    status.debug = sys.exec("uci get pon.global.event_debug 2>/dev/null | tr -d '\\n'") or "0"

    status.tx_packets = helpers_run("pon_get_tx_packets") or "0"
    status.rx_packets = helpers_run("pon_get_rx_packets") or "0"
    status.tx_bytes = helpers_run("pon_get_tx_bytes") or "0"
    status.rx_bytes = helpers_run("pon_get_rx_bytes") or "0"

    luci.http.prepare_content("application/json")
    luci.http.write_json(status)
end

function action_api_optical()
    local sys = require "luci.sys"
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

    info.state = sys.exec("cat /proc/tc3162/omci_state 2>/dev/null | tr -d '\\n'") or "unknown"
    info.eqid = sys.exec("cat /proc/tc3162/omci_eqid 2>/dev/null | tr -d '\\n'") or "N/A"
    info.sn = sys.exec("cat /proc/tc3162/omci_sn 2>/dev/null | tr -d '\\n'") or "N/A"
    info.omcimgr_pid = sys.exec("cat /var/run/omcimgr.pid 2>/dev/null | tr -d '\\n'") or ""
    info.omcimgr_running = sys.call("pidof omciMgr >/dev/null 2>&1") == 0

    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

function action_api_apply()
    local json = require "luci.jsonc"
    local sys = require "luci.sys"

    local raw = luci.http.content()
    local params = json.parse(raw) or {}

    if params.fec_rx then
        sys.call(string.format(
            ". %s && pon_set_fec_cfg %s",
            HELPERS, params.fec_rx))
        sys.call(string.format(
            "uci set pon.global.fec_rx='%s' && uci commit pon",
            params.fec_rx))
    end

    if params.debug then
        sys.call(string.format(
            ". %s && pon_set_dbg_level %s",
            HELPERS, params.debug == "1" and "enable" or "disable"))
        sys.call(string.format(
            "uci set pon.global.event_debug='%s' && uci commit pon",
            params.debug))
    end

    if params.pm_flag then
        sys.call(string.format(
            ". %s && omci_set_pm_flag %s",
            HELPERS, params.pm_flag))
        sys.call(string.format(
            "uci set pon.omci.pm_flag='%s' && uci commit pon",
            params.pm_flag))
    end

    if params.slid then
        sys.call(string.format(
            ". %s && pon_set_ont_password '%s'",
            HELPERS, params.slid))
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({ success = true })
end
