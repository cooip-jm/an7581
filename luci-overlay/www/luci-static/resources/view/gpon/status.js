'use strict';
'require form';
'require rpc';
'require uci';

var callPonStatus = rpc.declare({
	object: 'file',
	method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_full_status'] },
	expect: { '': {} }
});

var callPonService = rpc.declare({
	object: 'file',
	method: 'exec',
	params: { command: ['/bin/sh', '-c', ''] },
	expect: { '': {} }
});

return L.Class.extend({
	title: _('PON Status'),

	load: function() {
		return L.resolveDefault(callPonStatus(), {});
	},

	render: function(data) {
		var info = data || {};
		var status_text = info.pon_state || 'Unknown';
		var link_state = info.link_state || 'Down';
		var fec_rx = info.fec_rx || 0;
		var omcimgr = info.omcimgr_running || false;
		var ponmgr = info.ponmgr_running || false;

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ E('strong', {}, [_('PON State')]) ]),
				E('td', { 'class': 'td left' }, [ status_text ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Link State')]) ]),
				E('td', { 'class': 'td left' }, [
					link_state === 'Connected'
						? E('span', { 'style': 'color:green;font-weight:bold' }, [_('Connected')])
						: E('span', { 'style': 'color:red' }, [_('Not Connected')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('FEC (Downstream)')]) ]),
				E('td', { 'class': 'td left' }, [
					fec_rx ? E('span', { 'style': 'color:green' }, [_('Enabled')])
					       : E('span', {}, [_('Disabled')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, ['omciMgr']) ]),
				E('td', { 'class': 'td left' }, [
					omcimgr ? E('span', { 'style': 'color:green' }, [_('Running')])
					        : E('span', { 'style': 'color:red' }, [_('Stopped')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, ['ponmgr']) ]),
				E('td', { 'class': 'td left' }, [
					ponmgr ? E('span', { 'style': 'color:green' }, [_('Running')])
					        : E('span', { 'style': 'color:red' }, [_('Stopped')])
				])
			])
		]);

		var optical_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ E('strong', {}, [_('TX Power')]) ]),
				E('td', { 'class': 'td left' }, [ (info.tx_power || 'N/A') + ' dBm' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('RX Power')]) ]),
				E('td', { 'class': 'td left' }, [ (info.rx_power || 'N/A') + ' dBm' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Temperature')]) ]),
				E('td', { 'class': 'td left' }, [ (info.temperature || 'N/A') + ' C' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Bias Current')]) ]),
				E('td', { 'class': 'td left' }, [ (info.bias_current || 'N/A') + ' uA' ])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [ E('strong', {}, [_('Supply Voltage')]) ]),
				E('td', { 'class': 'td left' }, [ (info.voltage || 'N/A') + ' uV' ])
			])
		]);

		return E('div', {}, [
			E('h2', {}, [_('PON Status')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [_('PON Link Information')]),
				table
			]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [_('Optical Transceiver')]),
				optical_table
			])
		]);
	}
});
