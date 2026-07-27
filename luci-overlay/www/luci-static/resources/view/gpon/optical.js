'use strict';
'require view';
'require rpc';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'Optical Module': '光模块',
	'Temperature': '温度',
	'Bias Current': '偏置电流',
	'Supply Voltage': '供电电压',
	'TX Power': '发射功率',
	'RX Power': '接收功率',
	'TX Bytes': '发送字节数',
	'RX Bytes': '接收字节数',
	'TX Packets': '发送包数',
	'RX Packets': '接收包数',
	'PON Counters': 'PON 计数器',
	'Transceiver Info': '收发器信息'
});
var T = function(s) { return (window.TR && window.TR[s] !== undefined) ? window.TR[s] : s; };

var callRead = rpc.declare({
	object: 'file', method: 'read',
	expect: { data: '' }
});

function readPonFile(basePath, filename) {
	return L.resolveDefault(callRead({ path: basePath + '/' + filename }), '').then(function(res) {
		if (res && res.data !== undefined) return String(res.data).trim();
		return '';
	});
}

return view.extend({
	title: T('Optical Module'),

	load: function() {
		return L.resolveDefault(uci.load('pon'), null).then(function() {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			return Promise.all([
				readPonFile(basePath, 'pon_temp'),
				readPonFile(basePath, 'pon_bias'),
				readPonFile(basePath, 'pon_voltage'),
				readPonFile(basePath, 'pon_txpower'),
				readPonFile(basePath, 'pon_rxpower'),
				readPonFile(basePath, 'pon_txbytes'),
				readPonFile(basePath, 'pon_rxbytes'),
				readPonFile(basePath, 'pon_txpkts'),
				readPonFile(basePath, 'pon_rxpkts')
			]).then(function(results) {
				return {
					temp: results[0] || 'N/A',
					bias: results[1] || 'N/A',
					voltage: results[2] || 'N/A',
					txpower: results[3] || 'N/A',
					rxpower: results[4] || 'N/A',
					txbytes: results[5] || 'N/A',
					rxbytes: results[6] || 'N/A',
					txpkts: results[7] || 'N/A',
					rxpkts: results[8] || 'N/A'
				};
			});
		});
	},

	render: function(info) {
		info = info || {};

		var makeRow = function(label, value, unit) {
			return E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [label]),
				E('td', { 'class': 'td left' }, [value !== 'N/A' ? value + ' ' + unit : 'N/A'])
			]);
		};

		var optical_table = E('table', { 'class': 'table' }, [
			makeRow(T('Temperature'), info.temp, '\u00b0C'),
			makeRow(T('Bias Current'), info.bias, '\u00b5A'),
			makeRow(T('Supply Voltage'), info.voltage, 'mV'),
			makeRow(T('TX Power'), info.txpower, 'dBm'),
			makeRow(T('RX Power'), info.rxpower, 'dBm')
		]);

		var counter_table = E('table', { 'class': 'table' }, [
			makeRow(T('TX Bytes'), info.txbytes, ''),
			makeRow(T('RX Bytes'), info.rxbytes, ''),
			makeRow(T('TX Packets'), info.txpkts, ''),
			makeRow(T('RX Packets'), info.rxpkts, '')
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [T('Optical Module')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('Transceiver Info')]),
				optical_table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('PON Counters')]),
				counter_table
			])
		]);
	}
});
