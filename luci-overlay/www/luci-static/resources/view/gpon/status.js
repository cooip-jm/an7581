'use strict';
'require baseclass';
'require rpc';

var callPonStatus = rpc.declare({
	object: 'file',
	method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_full_status'] },
	expect: { '': {} }
});

return baseclass.extend({
	title: _('PON Status'),

	load: function() {
		return L.resolveDefault(callPonStatus(), null);
	},

	render: function(data) {
		if (!data)
			return E('div', { 'class': 'alert-message warning' }, [
				E('p', {}, [_('Unable to retrieve PON status. The PON subsystem may not be available on this system.')])
			]);

		var status_text = data.pon_state || 'Unknown';
		var link_state = data.link_state || 'Down';
		var fec_rx = data.fec_rx || 0;
		var omcimgr = data.omcimgr_running || false;
		var ponmgr = data.ponmgr_running || false;

		var status_icon = link_state === 'Connected'
			? E('span', { 'class': 'label label-success' }, [status_text])
			: E('span', { 'class': 'label' }, [status_text]);

		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [_('PON State')]),
				E('td', { 'class': 'td left' }, [status_icon])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Link State')]),
				E('td', { 'class': 'td left' }, [
					link_state === 'Connected'
						? E('span', { 'class': 'label label-success' }, [_('Connected')])
						: E('span', { 'class': 'label label-important' }, [_('Not Connected')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('FEC (Downstream)')]),
				E('td', { 'class': 'td left' }, [
					fec_rx ? E('span', { 'class': 'label label-success' }, [_('Enabled')])
					       : E('span', { 'class': 'label' }, [_('Disabled')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, ['ponmgr']),
				E('td', { 'class': 'td left' }, [
					ponmgr ? E('span', { 'class': 'label label-success' }, [_('Running')])
				        : E('span', { 'class': 'label label-important' }, [_('Stopped')])
				])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, ['omciMgr']),
				E('td', { 'class': 'td left' }, [
					omcimgr ? E('span', { 'class': 'label label-success' }, [_('Running')])
				        : E('span', { 'class': 'label label-important' }, [_('Stopped')])
				])
			])
		]);

		var optical_table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [_('TX Power')]),
				E('td', { 'class': 'td left' }, [data.tx_power ? data.tx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('RX Power')]),
				E('td', { 'class': 'td left' }, [data.rx_power ? data.rx_power + ' dBm' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Temperature')]),
				E('td', { 'class': 'td left' }, [data.temperature ? data.temperature + ' \u00b0C' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Bias Current')]),
				E('td', { 'class': 'td left' }, [data.bias_current ? data.bias_current + ' \u00b5A' : 'N/A'])
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left' }, [_('Supply Voltage')]),
				E('td', { 'class': 'td left' }, [data.voltage ? data.voltage + ' mV' : 'N/A'])
			])
		]);

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [_('PON Status')]),
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
