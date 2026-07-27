'use strict';
'require view';
'require rpc';
'require uci';

if (!window.TR) window.TR = {};
Object.assign(window.TR, {
	'OMCI Status': 'OMCI 状态',
	'OMCI Manager Status': 'OMCI 管理器状态',
	'Equipment ID': '设备 ID',
	'Serial Number': '序列号',
	'OMCI State': 'OMCI 状态',
	'Running': '运行中',
	'Stopped': '已停止',
	'OMCI Manager': 'OMCI 管理器',
	'PID': '进程 ID',
	'PON Mode': 'PON 模式',
	'Auto-detect': '自动检测',
	'GPON': 'GPON',
	'EPON': 'EPON',
	'XGS-PON': 'XGS-PON'
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

return view.extend({
	title: T('OMCI Status'),

	load: function() {
		return L.resolveDefault(uci.load('pon'), null).then(function() {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			return Promise.all([
				readPonFile(basePath, 'omci_state'),
				readPonFile(basePath, 'omci_eqid'),
				readPonFile(basePath, 'omci_sn'),
				readFile('/proc/net/omci_state'),
				readFile('/proc/net/omci_eqid'),
				readFile('/proc/net/omci_sn')
			]).then(function(results) {
				return {
					omci_state: results[0] || results[3] || 'N/A',
					omci_eqid: results[1] || results[4] || 'N/A',
					omci_sn: results[2] || results[5] || 'N/A'
				};
			});
		});
	},

	render: function(info) {
		info = info || {};

		var omci_state = info.omci_state || 'Unknown';
		var is_running = (omci_state !== 'Unknown' && omci_state !== '');

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI State')]),
				E('td', { 'class': 'td left' }, [
					is_running
						? E('span', { 'class': 'label label-success' }, [omci_state])
						: E('span', { 'class': 'label label-important' }, [T('Stopped')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Equipment ID')]),
				E('td', { 'class': 'td left' }, [info.omci_eqid !== 'N/A' ? info.omci_eqid : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [T('Serial Number')]),
				E('td', { 'class': 'td left' }, [info.omci_sn !== 'N/A' ? info.omci_sn : 'N/A'])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [T('OMCI Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('OMCI Manager Status')]),
				table
			])
		]);
	}
});
