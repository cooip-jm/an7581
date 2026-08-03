'use strict';
'require view';
'require form';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'PON Configuration': 'PON 配置',
	'Enable PON Subsystem': '启用 PON 子系统',
	'Start the PON driver stack, BOSA transceiver, and management daemons on boot.': '开机启动 PON 驱动栈、BOSA 收发器和管理进程。',
	'PON Mode': 'PON 模式',
	'Select the PON protocol. Auto-detect is recommended.': '选择 PON 协议。建议使用自动检测。',
	'Auto-detect': '自动检测',
	'GPON (ITU-T G.984)': 'GPON (ITU-T G.984)',
	'EPON (IEEE 802.3ah)': 'EPON (IEEE 802.3ah)',
	'XGS-PON (ITU-T G.9807.1)': 'XGS-PON (ITU-T G.9807.1)',
	'BOSA Transceiver Chip': 'BOSA 收发器芯片',
	'EN7572 (internal)': 'EN7572 (内置)',
	'GN25L98': 'GN25L98', 'GN28L96': 'GN28L96', 'UX3320': 'UX3320',
	'Global Settings': '全局设置',
	'FEC Settings': 'FEC 设置',
	'RX FEC (Downstream)': 'RX FEC (下行)',
	'TX FEC (Upstream)': 'TX FEC (上行)',
	'Diagnostics': '诊断',
	'Enable PON Debug Logging': '启用 PON 调试日志',
	'Enable O1 Init Report': '启用 O1 初始化报告',
	'OMCI Settings': 'OMCI 设置',
	'Enable OMCI Manager': '启用 OMCI 管理器',
	'Performance Monitor': '性能监控',
	'PON VLAN': 'PON VLAN',
	'Enable VLAN Tagging': '启用 VLAN 标签',
	'Configure VLAN tag handling on the PON interface.': '配置 PON 接口的 VLAN 标签处理。',
	'VLAN Mode': 'VLAN 模式',
	'Transparent (no VLAN processing)': '透明 (不处理 VLAN)',
	'Tag (add/replace VLAN tag)': '标签 (添加/替换 VLAN 标签)',
	'Translate (rewrite VLAN tag)': '转换 (重写 VLAN 标签)',
	'VLAN ID': 'VLAN ID',
	'VLAN identifier (1-4094). Required for tag and translate modes.': 'VLAN 标识符 (1-4094)，标签和转换模式必需。',
	'VLAN Priority': 'VLAN 优先级',
	'802.1p priority (0-7).': '802.1p 优先级 (0-7)。',
	'Configure PON hardware parameters for the Nokia XG-040G-MD (AN7581).': '配置 Nokia XG-040G-MD (AN7581) 的 PON 硬件参数。',
	'Save & Apply': '保存并应用', 'Save': '保存', 'Reset': '重置',
	'Loading view…': '加载中…',
	'Configuration applied to PON daemons.': '配置已应用到 PON 守护进程。',
	'Failed to apply configuration.': '应用配置失败。'
});
var T = function(s) { return (window.TR && window.TR[s] !== undefined) ? window.TR[s] : s; };

function applyPonConfig() {
	return fetch('/cgi-bin/pon-apply?apply').then(function(r) {
		return r.json();
	}).then(function(res) {
		return (res && res.code === 0);
	}).catch(function() {
		return false;
	});
}

return view.extend({
	title: _('PON Configuration'),

	load: function() {
		return L.resolveDefault(uci.load('pon'), null);
	},

	render: function() {
		var m, s, o;

		m = new form.Map('pon', _('PON Configuration'),
			_('Configure PON hardware parameters for the Nokia XG-040G-MD (AN7581).'));

		s = m.section(form.TypedSection, 'global', _('Global Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable PON Subsystem'),
			_('Start the PON driver stack, BOSA transceiver, and management daemons on boot.'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.ListValue, 'pon_mode', _('PON Mode'),
			_('Select the PON protocol. Auto-detect is recommended.'));
		o.value('auto', _('Auto-detect'));
		o.value('gpon', _('GPON (ITU-T G.984)'));
		o.value('epon', _('EPON (IEEE 802.3ah)'));
		o.value('xgspon', _('XGS-PON (ITU-T G.9807.1)'));
		o.value('xgpon', _('XGPON (10G symmetric)'));
		o.default = 'auto';
		o.disabled = true;

		o = s.option(form.ListValue, 'bosa_chip', _('BOSA Transceiver Chip'));
		o.value('en7572', _('EN7572 (internal)'));
		o.value('gn25l98', _('GN25L98'));
		o.value('gn28l96', _('GN28L96'));
		o.value('ux3320', _('UX3320'));
		o.default = 'en7572';
		o.disabled = true;

		s = m.section(form.TypedSection, 'global', _('FEC Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'fec_rx', _('RX FEC (Downstream)'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.Flag, 'fec_tx', _('TX FEC (Upstream)'));
		o.default = '1';
		o.rmempty = false;

		s = m.section(form.TypedSection, 'global', _('Diagnostics'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'event_debug', _('Enable PON Debug Logging'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Flag, 'init_report', _('Enable O1 Init Report'));
		o.default = '1';
		o.rmempty = false;

		s = m.section(form.TypedSection, 'omci', _('OMCI Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable OMCI Manager'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.ListValue, 'pm_flag', _('Performance Monitor'));
		o.value('0', _('Disabled'));
		o.value('1', _('Enabled'));
		o.default = '0';

		/* ── PON VLAN ────────────────────────────────────── */
		s = m.section(form.TypedSection, 'pon_vlan', _('PON VLAN'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable VLAN Tagging'),
			_('Configure VLAN tag handling on the PON interface.'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.ListValue, 'mode', _('VLAN Mode'));
		o.value('transparent', _('Transparent (no VLAN processing)'));
		o.value('tag', _('Tag (add/replace VLAN tag)'));
		o.value('translate', _('Translate (rewrite VLAN tag)'));
		o.default = 'transparent';
		o.rmempty = false;

		o = s.option(form.Value, 'vid', _('VLAN ID'),
			_('VLAN identifier (1-4094). Required for tag and translate modes.'));
		o.datatype = 'range(1,4094)';
		o.rmempty = true;
		o.placeholder = '100';
		o.depends('mode', 'tag');
		o.depends('mode', 'translate');

		o = s.option(form.ListValue, 'priority', _('VLAN Priority'),
			_('802.1p priority (0-7).'));
		for (var p = 0; p <= 7; p++)
			o.value(String(p), String(p));
		o.default = '0';
		o.rmempty = false;
		o.depends('mode', 'tag');
		o.depends('mode', 'translate');

		var origSave = m.save.bind(m);
		m.save = function() {
			return origSave().then(function(ok) {
				if (ok === true) return applyPonConfig();
			});
		};

		return m.render();
	}
});
