'use strict';
'require view';
'require form';
'require rpc';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'OLT Authentication': 'OLT 认证',
	'Configure ONT serial number and password for OLT authentication.': '配置 ONT 序列号和密码用于 OLT 认证。',
	'Serial Number (SN)': '序列号 (SN)',
	'Vendor ID': '厂商 ID',
	'4-byte ASCII vendor identifier (e.g. ALCL, HWTC).': '4 字节 ASCII 厂商标识符 (如 ALCL, HWTC)。',
	'VSSD (Vendor-Specific Serial)': 'VSSD (厂商特定序列号)',
	'8-byte vendor-specific serial number in hex (8 hex digits). Combined with Vendor ID forms the 12-byte ONT SN.': '8 字节十六进制厂商特定序列号 (8 位 hex)。与厂商 ID 组合成 12 字节 ONT 序列号。',
	'Must be exactly 8 hex digits (0-9, a-f).': '必须为 8 位十六进制数字 (0-9, a-f)。',
	'SLID / Password Authentication': 'SLID / 密码认证',
	'Enable Password Authentication': '启用密码认证',
	'Disable Password Transmission': '禁止发送密码',
	'When enabled, the ONT will not send the password/PLOAM to the OLT during registration.': '启用后，ONT 注册时不向 OLT 发送密码/PLOAM。',
	'ONT Password (SLID)': 'ONT 密码 (SLID)',
	'Password for OLT authentication. ASCII: max 10 characters. HEX: max 20 hex digits.': 'OLT 认证密码。ASCII 模式：最多 10 个字符。HEX 模式：最多 20 位十六进制。',
	'SLID Format': 'SLID 格式',
	'ASCII Mode (max 10 characters)': 'ASCII 模式 (最多 10 个字符)',
	'HEX Mode (max 20 hex digits)': 'HEX 模式 (最多 20 位十六进制)',
	'LOID / Logical ID Authentication': 'LOID / 逻辑 ID 认证',
	'Enable LOID Authentication': '启用 LOID 认证',
	'Logical ID': '逻辑 ID',
	'Logic Identifier for OLT registration. Max 24 characters.': 'OLT 注册的逻辑标识符，最多 24 个字符。',
	'LOID Password': 'LOID 密码',
	'Direct Password Authentication': '直接密码认证',
	'ONT Password': 'ONT 密码',
	'OMCI State': 'OMCI 状态',
	'Authentication Status': '认证状态',
	'O5 — Authenticated': 'O5 — 已认证',
	'O4 — Ranging': 'O4 — 测距中',
	'O2/O3 — Serial Number': 'O2/O3 — 序列号注册中',
	'O1 — Not Started': 'O1 — 未开始',
	'Current PON State': '当前 PON 状态',
	'Connected': '已连接',
	'Initializing': '初始化中',
	'Unknown': '未知',
	'Save & Apply': '保存并应用', 'Save': '保存', 'Reset': '重置',
	'Configuration applied to PON daemons.': '配置已应用到 PON 守护进程。',
	'Failed to apply configuration.': '应用配置失败。',
	'Saved. PON configuration applied.': '已保存，PON 配置已应用。'
});
var T = function(s) { return (window.TR && window.TR[s] !== undefined) ? window.TR[s] : s; };

var callRead = rpc.declare({
	object: 'file', method: 'read',
	params: ['path'],
	expect: { '': {} }
});

function readFile(path) {
	return L.resolveDefault(callRead(path), '').then(function(res) {
		if (res && res.data !== undefined) return String(res.data).trim();
		return '';
	});
}

function applyPonConfig() {
	return fetch('/cgi-bin/pon-apply?apply').then(function(r) {
		return r.json();
	}).then(function(res) {
		return (res && res.code === 0);
	}).catch(function() { return false; });
}

function getLinkState(pon_state) {
	switch (pon_state) {
		case 'O5': case 'O5_2': return 'Connected';
		case 'O7': return 'Emergency Stop';
		case 'O1': case 'O2_3': case 'O4': return 'Initializing';
		default: return 'Unknown';
	}
}

function getAuthStatus(pon_state) {
	switch (pon_state) {
		case 'O5': case 'O5_2': return T('O5 — Authenticated');
		case 'O4': return T('O4 — Ranging');
		case 'O2_3': return T('O2/O3 — Serial Number');
		case 'O1': return T('O1 — Not Started');
		default: return T('Unknown');
	}
}

return view.extend({
	title: _('OLT Authentication'),

	load: function() {
		return Promise.all([
			L.resolveDefault(uci.load('pon_auth'), null),
			L.resolveDefault(uci.load('pon'), null)
		]).then(function() {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			return readFile(basePath + '/omci_state');
		}).then(function(omci_state) {
			return { omci_state: omci_state || 'N/A' };
		});
	},

	render: function(info) {
		info = info || {};
		var m, s, o;

		m = new form.Map('pon_auth', _('OLT Authentication'),
			_('Configure ONT serial number and password for OLT authentication.'));

	/* ── Current Auth Status ────────────────────────── */
	s = m.section(form.TypedSection, 'sn', _('Current PON State'));
	s.anonymous = true;
	s.addremove = false;

	var omci_state = info.omci_state || 'N/A';
	var link_state = getLinkState(omci_state);
	var auth_status = getAuthStatus(omci_state);
	var state_class = (link_state === 'Connected') ? 'label label-success'
		: (link_state === 'Initializing') ? 'label label-warning'
		: 'label label-secondary';
	s.description = '<span class="' + state_class + '">' + _('OMCI State') + ': ' + omci_state + '</span> — ' + auth_status;

		/* ── Serial Number (SN) ─────────────────────────── */
		s = m.section(form.TypedSection, 'sn', _('Serial Number (SN)'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Value, 'vendor_id', _('Vendor ID'),
			_('4-byte ASCII vendor identifier (e.g. ALCL, HWTC).'));
		o.datatype = 'maxlength(4)';
		o.rmempty = true;
		o.placeholder = 'ALCL';

		o = s.option(form.Value, 'vssd', _('VSSD (Vendor-Specific Serial)'),
			_('8-byte vendor-specific serial number in hex (8 hex digits). Combined with Vendor ID forms the 12-byte ONT SN.'));
		o.datatype = 'maxlength(8)';
		o.rmempty = true;
		o.placeholder = '00000000';
		o.validate = function(section_id, value) {
			if (value && !/^[0-9a-fA-F]{8}$/.test(value))
				return _('Must be exactly 8 hex digits (0-9, a-f).');
			return true;
		};

		/* ── SLID / Password ────────────────────────────── */
		s = m.section(form.TypedSection, 'slid', _('SLID / Password Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable Password Authentication'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Flag, 'password_disabled', _('Disable Password Transmission'),
			_('When enabled, the ONT will not send the password/PLOAM to the OLT during registration.'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'value', _('ONT Password (SLID)'),
			_('Password for OLT authentication. ASCII: max 10 characters. HEX: max 20 hex digits.'));
		o.datatype = 'maxlength(20)';
		o.rmempty = true;
		o.password = true;
		o.depends('password_disabled', '0');

		o = s.option(form.ListValue, 'mode', _('SLID Format'));
		o.value('ascii', _('ASCII Mode (max 10 characters)'));
		o.value('hex', _('HEX Mode (max 20 hex digits)'));
		o.default = 'ascii';
		o.rmempty = false;
		o.depends('password_disabled', '0');

		/* ── LOID ───────────────────────────────────────── */
		s = m.section(form.TypedSection, 'loid', _('LOID / Logical ID Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable LOID Authentication'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'value', _('Logical ID'),
			_('Logic Identifier for OLT registration. Max 24 characters.'));
		o.datatype = 'maxlength(24)';
		o.rmempty = true;

		o = s.option(form.Value, 'password', _('LOID Password'));
		o.datatype = 'maxlength(12)';
		o.rmempty = true;
		o.password = true;

		/* ── Direct Password ────────────────────────────── */
		s = m.section(form.TypedSection, 'password', _('Direct Password Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Value, 'value', _('ONT Password'));
		o.datatype = 'maxlength(20)';
		o.rmempty = true;
		o.password = true;

		var origSave = m.save.bind(m);
		m.save = function() {
			return origSave().then(function(ok) {
				if (ok === true) return applyPonConfig();
			});
		};

		return m.render();
	}
});
