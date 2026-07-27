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
	'OMCI Serial Number': 'OMCI 序列号'
});
var T = function(s) { return (window.TR && window.TR[s] !== undefined) ? window.TR[s] : s; };

var callRead = rpc.declare({
	object: 'file', method: 'read',
	params: ['path'],
	expect: { data: '' }
});

function readFile(path) {
	return L.resolveDefault(callRead({ path: path }), '').then(function(res) {
		if (res && res.data !== undefined) return String(res.data).trim();
		return '';
	});
}

function readPonFile(basePath, filename) {
	return readFile(basePath + '/' + filename);
}

return view.extend({
	title: T('PON Status'),

	load: function() {
		return L.resolveDefault(uci.load('pon'), null).then(function() {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			return Promise.all([
				readPonFile(basePath, 'pon_txpower'),
				readPonFile(basePath, 'pon_rxpower'),
				readPonFile(basePath, 'pon_temp'),
				readPonFile(basePath, 'pon_bias'),
				readPonFile(basePath, 'pon_voltage'),
				readPonFile(basePath, 'omci_state'),
				readPonFile(basePath, 'omci_eqid'),
				readPonFile(basePath, 'omci_sn')
			]).then(function(results) {
				return {
					tx_power: results[0] || 'N/A',
					rx_power: results[1] || 'N/A',
					temperature: results[2] || 'N/A',
					bias_current: results[3] || 'N/A',
					voltage: results[4] || 'N/A',
					omci_state: results[5] || 'N/A',
					omci_eqid: results[6] || 'N/A',
					omci_sn: results[7] || 'N/A'
				};
			});
		});
	},

	render: function(info) {
		info = info || {};

		var pon_state = info.omci_state || 'Unknown';
		var link_state = (pon_state === 'OMCI_Active') ? 'Connected' : 'Down';

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('PON State')]),
				E('td', { 'class': 'td left' }, [pon_state])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Link State')]),
				E('td', { 'class': 'td left' }, [
					link_state === 'Connected'
						? E('span', { 'class': 'label label-success' }, [T('Connected')])
						: E('span', { 'class': 'label label-important' }, [T('Not Connected')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('OMCI Equipment ID')]),
				E('td', { 'class': 'td left' }, [info.omci_eqid !== 'N/A' ? info.omci_eqid : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('OMCI Serial Number')]),
				E('td', { 'class': 'td left' }, [info.omci_sn !== 'N/A' ? info.omci_sn : 'N/A'])
			])
		]);

		var optical_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('TX Power')]),
				E('td', { 'class': 'td left' }, [info.tx_power !== 'N/A' ? info.tx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('RX Power')]),
				E('td', { 'class': 'td left' }, [info.rx_power !== 'N/A' ? info.rx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Temperature')]),
				E('td', { 'class': 'td left' }, [info.temperature !== 'N/A' ? info.temperature + ' \u00b0C' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Bias Current')]),
				E('td', { 'class': 'td left' }, [info.bias_current !== 'N/A' ? info.bias_current + ' \u00b5A' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Supply Voltage')]),
				E('td', { 'class': 'td left' }, [info.voltage !== 'N/A' ? info.voltage + ' mV' : 'N/A'])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [T('PON Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('PON Link Information')]),
				table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('Optical Transceiver')]),
				optical_table
			])
		]);
	}
});
