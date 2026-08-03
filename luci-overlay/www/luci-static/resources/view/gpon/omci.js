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
	'PON Mode': 'PON 模式',
	'Unknown': '未知',
	'Connected': '已连接',
	'Not Connected': '未连接',
	'Initializing': '初始化中',
	'Emergency Stop': '紧急停止',
	'Link State': '链路状态',
	'Authentication': '认证状态',
	'O5 — Authenticated': 'O5 — 已认证',
	'O4 — Ranging': 'O4 — 测距中',
	'O2/O3 — Serial Number': 'O2/O3 — 序列号注册中',
	'O1 — Not Started': 'O1 — 未开始',
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
	title: T('OMCI Status'),

	load: function() {
		return Promise.all([
			L.resolveDefault(uci.load('pon'), null),
			fetch('/cgi-bin/pon-status').then(function(r) { return r.json(); }).catch(function() { return null; })
		]).then(function(results) {
			var basePath = uci.get_first('pon', 'global', 'proc_path') || '/proc/tc3162';
			var pon_mode = uci.get_first('pon', 'global', 'pon_mode') || 'auto';
			var collect = results[1] || {};

			return Promise.all([
				readPonFile(basePath, 'omci_state'),
				readPonFile(basePath, 'omci_eqid'),
				readPonFile(basePath, 'omci_sn')
			]).then(function(r) {
				return {
					omci_state: r[0] || 'N/A',
					omci_eqid: r[1] || 'N/A',
					omci_sn: r[2] || 'N/A',
					omci_running: collect.omci_running || 'N/A',
					pon_mode: pon_mode
				};
			});
		});
	},

	render: function(info) {
		info = info || {};

		var omci_state = info.omci_state || 'N/A';
		var omci_running = (info.omci_running === 'yes');
		var link_state = getLinkState(omci_state);
		var auth_status = getAuthStatus(omci_state);

		var state_class;
		switch (link_state) {
			case 'Connected': state_class = 'label label-success'; break;
			case 'Initializing': state_class = 'label label-warning'; break;
			case 'Emergency Stop': state_class = 'label label-important'; break;
			default: state_class = 'label label-secondary';
		}

		var auth_class;
		switch (auth_status) {
			case T('O5 — Authenticated'): auth_class = 'label label-success'; break;
			case T('O4 — Ranging'): case T('O2/O3 — Serial Number'): auth_class = 'label label-warning'; break;
			default: auth_class = 'label label-secondary';
		}

		var state_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI State')]),
				E('td', { 'class': 'td left' }, [
					E('span', { 'class': state_class }, [omci_state])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Link State')]),
				E('td', { 'class': 'td left' }, [
					E('span', { 'class': state_class }, [T(link_state)])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Authentication')]),
				E('td', { 'class': 'td left' }, [
					E('span', { 'class': auth_class }, [auth_status])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('PON Mode')]),
				E('td', { 'class': 'td left' }, [info.pon_mode || 'Unknown'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Equipment ID')]),
				E('td', { 'class': 'td left' }, [info.omci_eqid])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('Serial Number')]),
				E('td', { 'class': 'td left' }, [info.omci_sn])
			])
		]);

		var daemon_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [T('OMCI Manager')]),
				E('td', { 'class': 'td left' }, [
					omci_running
						? E('span', { 'class': 'label label-success' }, [T('Running')])
						: E('span', { 'class': 'label label-important' }, [T('Stopped')])
				])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [T('OMCI Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('OMCI Manager Status')]),
				state_table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [T('Daemon Status')]),
				daemon_table
			])
		]);
	}
});
