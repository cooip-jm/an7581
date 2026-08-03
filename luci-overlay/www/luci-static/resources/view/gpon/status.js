'use strict';
'require view';
'require rpc';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'PON Status': 'PON 状态',
	'PON State': 'PON 状态',
	'Link State': '链路状态',
	'Connected': '已连接',
	'Not Connected': '未连接',
	'Initializing': '初始化中',
	'Emergency Stop': '紧急停止',
	'Unknown': '未知',
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
	'OMCI Equipment ID': 'OMCI 设备 ID',
	'OMCI Serial Number': 'OMCI 序列号',
	'PON Mode': 'PON 模式',
	'FEC Status': 'FEC 状态',
	'OMCI Manager': 'OMCI 管理器',
	'PON Manager': 'PON 管理器',
	'Daemon Status': '守护进程状态',
	'Auto-detect': '自动检测',
	'GPON (ITU-T G.984)': 'GPON (ITU-T G.984)',
	'EPON (IEEE 802.3ah)': 'EPON (IEEE 802.3ah)',
	'XGS-PON (ITU-T G.9807.1)': 'XGS-PON (ITU-T G.9807.1)',
	'Type B Protect': 'Type B 保护',
	'NG2 Tuning': 'NG2 调优'
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

function readPonFile(basePath, filename) {
	return readFile(basePath + '/' + filename);
}

function getLinkState(pon_state) {
	switch (pon_state) {
		case 'O5': case 'O5_2': return 'Connected';
		case 'O7': return 'Emergency Stop';
		case 'O1': case 'O2_3': case 'O4': return 'Initializing';
		case 'O6': return 'Type B Protect';
		case 'O8': case 'O9': return 'NG2 Tuning';
		default: return 'Unknown';
	}
}

function getLinkStateClass(link_state) {
	switch (link_state) {
		case 'Connected': return 'label label-success';
		case 'Initializing': return 'label label-warning';
		case 'Emergency Stop': return 'label label-important';
		default: return 'label label-secondary';
	}
}

function getPonModeName(mode) {
	switch (mode) {
		case 'gpon': return 'GPON (ITU-T G.984)';
		case 'epon': return 'EPON (IEEE 802.3ah)';
		case 'xgspon': return 'XGS-PON (ITU-T G.9807.1)';
		case 'xgpon': return 'XGPON (10G symmetric)';
		case 'auto': return 'Auto-detect';
		default: return mode || 'Unknown';
	}
}

return view.extend({
	title: T('PON Status'),

	load: function() {
		return L.resolveDefault(uci.load('pon'), null).then(function() {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			var pon_mode = uci.get_first('pon', 'global', 'pon_mode') || 'auto';
			var fec_rx = uci.get_first('pon', 'global', 'fec_rx') || '0';

			return Promise.all([
				readPonFile(basePath, 'pon_txpower'),
				readPonFile(basePath, 'pon_rxpower'),
				readPonFile(basePath, 'pon_temp'),
				readPonFile(basePath, 'pon_bias'),
				readPonFile(basePath, 'pon_voltage'),
				readPonFile(basePath, 'omci_state'),
				readPonFile(basePath, 'omci_eqid'),
				readPonFile(basePath, 'omci_sn'),
				readFile('/var/run/omcimgr.pid'),
				readFile('/var/run/ponmgr.pid')
			]).then(function(results) {
				return {
					tx_power: results[0] || 'N/A',
					rx_power: results[1] || 'N/A',
					temperature: results[2] || 'N/A',
					bias_current: results[3] || 'N/A',
					voltage: results[4] || 'N/A',
					omci_state: results[5] || 'N/A',
					omci_eqid: results[6] || 'N/A',
					omci_sn: results[7] || 'N/A',
					omcimgr_pid: results[8] || '',
					ponmgr_pid: results[9] || '',
					pon_mode: pon_mode,
					fec_rx: fec_rx
				};
			});
		});
	},

	render: function(info) {
		info = info || {};

		var pon_state = info.omci_state || 'Unknown';
		var link_state = getLinkState(pon_state);
		var link_class = getLinkStateClass(link_state);
		var omcimgr_running = info.omcimgr_pid && info.omcimgr_pid.length > 0;
		var ponmgr_running = info.ponmgr_pid && info.ponmgr_pid.length > 0;

		var status_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('PON State')]),
				E('td', { 'class': 'td left' }, [pon_state])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Link State')]),
				E('td', { 'class': 'td left' }, [
					E('span', { 'class': link_class }, [T(link_state)])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('PON Mode')]),
				E('td', { 'class': 'td left' }, [getPonModeName(info.pon_mode)])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('FEC Status')]),
				E('td', { 'class': 'td left' }, [
					info.fec_rx === '1'
						? E('span', { 'class': 'label label-success' }, [T('Enabled')])
						: E('span', { 'class': 'label label-secondary' }, [T('Disabled')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI Equipment ID')]),
				E('td', { 'class': 'td left' }, [info.omci_eqid])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI Serial Number')]),
				E('td', { 'class': 'td left' }, [info.omci_sn])
			])
		]);

		var daemon_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI Manager')]),
				E('td', { 'class': 'td left' }, [
					omcimgr_running
						? E('span', { 'class': 'label label-success' }, [T('Running') + ' (PID: ' + info.omcimgr_pid + ')'])
						: E('span', { 'class': 'label label-important' }, [T('Stopped')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('PON Manager')]),
				E('td', { 'class': 'td left' }, [
					ponmgr_running
						? E('span', { 'class': 'label label-success' }, [T('Running') + ' (PID: ' + info.ponmgr_pid + ')'])
						: E('span', { 'class': 'label label-important' }, [T('Stopped')])
				])
			])
		]);

		var optical_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('TX Power')]),
				E('td', { 'class': 'td left' }, [info.tx_power !== 'N/A' ? info.tx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('RX Power')]),
				E('td', { 'class': 'td left' }, [info.rx_power !== 'N/A' ? info.rx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Temperature')]),
				E('td', { 'class': 'td left' }, [info.temperature !== 'N/A' ? info.temperature + ' \u00b0C' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Bias Current')]),
				E('td', { 'class': 'td left' }, [info.bias_current !== 'N/A' ? info.bias_current + ' \u00b5A' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Supply Voltage')]),
				E('td', { 'class': 'td left' }, [info.voltage !== 'N/A' ? info.voltage + ' mV' : 'N/A'])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [T('PON Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('PON Link Information')]),
				status_table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('Daemon Status')]),
				daemon_table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('Optical Transceiver')]),
				optical_table
			])
		]);
	}
});
