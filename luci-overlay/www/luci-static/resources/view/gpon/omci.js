'use strict';
'require view';
'require rpc';

var callOmciState = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', 'cat /proc/tc3162/omci_state 2>/dev/null || echo N/A'] },
	expect: { '': '' }
});
var callOmciEqid = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', 'cat /proc/tc3162/omci_eqid 2>/dev/null || echo N/A'] },
	expect: { '': '' }
});
var callOmciSn = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', 'cat /proc/tc3162/omci_sn 2>/dev/null || echo N/A'] },
	expect: { '': '' }
});
var callOmciRunning = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', 'pidof omciMgr >/dev/null 2>&1 && echo running || echo stopped'] },
	expect: { '': '' }
});

return view.extend({
	title: _('OMCI Status'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callOmciState, 'N/A'),
			L.resolveDefault(callOmciEqid, 'N/A'),
			L.resolveDefault(callOmciSn, 'N/A'),
			L.resolveDefault(callOmciRunning, 'stopped')
		]);
	},

	render: function(data) {
		var vals = data || ['N/A', 'N/A', 'N/A', 'stopped'];
		for (var i = 0; i < vals.length; i++)
			vals[i] = (vals[i] || '').trim();

		var running = vals[3] === 'running';

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [_('OMCI State')]),
				E('td', { 'class': 'td left' }, [vals[0]])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Equipment ID')]),
				E('td', { 'class': 'td left' }, [vals[1]])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Serial Number')]),
				E('td', { 'class': 'td left' }, [vals[2]])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, ['omciMgr']),
				E('td', { 'class': 'td left' }, [
					running
						? E('span', { 'class': 'label label-success' }, [_('Running')])
						: E('span', { 'class': 'label label-important' }, [_('Stopped')])
				])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [_('OMCI Status')]),
			E('div', { 'class': 'cbi-section' }, [table])
		]);
	}
});
