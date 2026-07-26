'use strict';
'require rpc';

var callOmciInfo = rpc.declare({
	object: 'file',
	method: 'exec',
	params: { command: ['/bin/sh', '-c', 'echo "{\"state\":\"$(cat /proc/tc3162/omci_state 2>/dev/null || echo unknown)\",\"eqid\":\"$(cat /proc/tc3162/omci_eqid 2>/dev/null || echo N/A)\",\"sn\":\"$(cat /proc/tc3162/omci_sn 2>/dev/null || echo N/A)\",\"running\":$(pidof omciMgr >/dev/null 2>&1 && echo true || echo false)}"'] },
	expect: { '': {} }
});

return L.Class.extend({
	title: _('OMCI Status'),

	load: function() {
		return L.resolveDefault(callOmciInfo(), {});
	},

	render: function(data) {
		var info = data || {};

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ E('strong', {}, [_('OMCI State')]) ]),
				E('td', { 'class': 'td left' }, [ info.state || 'N/A' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Equipment ID')]) ]),
				E('td', { 'class': 'td left' }, [ info.eqid || 'N/A' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Serial Number')]) ]),
				E('td', { 'class': 'td left' }, [ info.sn || 'N/A' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, ['omciMgr']) ]),
				E('td', { 'class': 'td left' }, [
					info.running
						? E('span', { 'style': 'color:green' }, [_('Running')])
						: E('span', { 'style': 'color:red' }, [_('Stopped')])
				])
			])
		]);

		return E('div', {}, [
			E('h2', {}, [_('OMCI Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [_('OMCI Management Interface')]),
				table
			])
		]);
	}
});
