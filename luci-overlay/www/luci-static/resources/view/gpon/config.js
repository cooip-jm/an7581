'use strict';
'require view';
'require form';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'PON Management': 'PON 管理',
	'PON Status': 'PON 状态',
	'PON Configuration': 'PON 配置',
	'OLT Authentication': 'OLT 认证',
	'Optical Module': '光模块',
	'OMCI Status': 'OMCI 状态',
	'PON State': 'PON 状态',
	'Link State': '链路状态',
	'Connected': '已连接',
	'Not Connected': '未连接',
	'FEC (Downstream)': '前向纠错 (下行)',
	'Enabled': '已启用',
	'Disabled': '已禁用',
	'Running': '运行中',
	'Stopped': '已停止',
	'TX Power': '发射功率',
	'RX Power': '接收功率',
	'Temperature': '温度',
	'Bias Current': '偏置电流',
	'Supply Voltage': '供电电压',
	'PON Link Information': 'PON 链路信息',
	'Optical Transceiver': '光收发器',
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
	'GN25L98': 'GN25L98',
	'GN28L96': 'GN28L96',
	'UX3320': 'UX3320',
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
	'Configure ONT serial number and password for OLT authentication.': '配置 ONT 序列号和密码用于 OLT 认证。',
	'OMCI State': 'OMCI 状态',
	'Equipment ID': '设备 ID',
	'Serial Number': '序列号',
	'OMCI Management Interface': 'OMCI 管理接口',
	'TX Power (dBm)': '发射功率 (dBm)',
	'RX Power (dBm)': '接收功率 (dBm)',
	'Temperature (\u00b0C)': '温度 (\u00b0C)',
	'Bias Current (\u00b5A)': '偏置电流 (\u00b5A)',
	'Supply Voltage (mV)': '供电电压 (mV)',
	'TX Packets': '发送包数',
	'RX Packets': '接收包数',
	'TX Bytes': '发送字节数',
	'RX Bytes': '接收字节数',
	'SFP/BOSA Optical Parameters': 'SFP/BOSA 光参数',
	'N/A': '无数据',
	'Unknown': '未知',
	'Hardware Info': '硬件信息',
	'Unable to retrieve PON status. The PON subsystem may not be available on this system.': '无法获取 PON 状态。当前系统可能不支持 PON 子系统。',
	'Save & Apply': '保存并应用',
	'Save': '保存',
	'Reset': '重置',
	'Loading view…': '加载中…'
});

return view.extend({
	title: _('PON Configuration'),

	load: function() {
		return Promise.all([
			L.resolveDefault(uci.load('pon'), null),
			L.resolveDefault(uci.load('pon_auth'), null)
		]);
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
		o.default = 'auto';
		o.readonly = true;

		o = s.option(form.ListValue, 'bosa_chip', _('BOSA Transceiver Chip'));
		o.value('en7572', _('EN7572 (internal)'));
		o.value('gn25l98', _('GN25L98'));
		o.value('gn28l96', _('GN28L96'));
		o.value('ux3320', _('UX3320'));
		o.default = 'en7572';
		o.readonly = true;

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

		o = s.option(form.ListValue, 'priority', _('VLAN Priority'),
			_('802.1p priority (0-7).'));
		for (var p = 0; p <= 7; p++)
			o.value(String(p), String(p));
		o.default = '0';
		o.rmempty = false;

		return m.render();
	}
});
