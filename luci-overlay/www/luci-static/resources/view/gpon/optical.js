'use strict';
'require rpc';

var callOpticalData = rpc.declare({
	object: 'file',
	method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; echo "{\"tx_power\":\""$(pon_get_tx_power_dbm)"\",\"rx_power\":\""$(pon_get_rx_power_dbm)"\",\"temperature\":\""$(pon_get_temperature)"\",\"bias_current\":\""$(pon_get_bias_current)"\",\"voltage\":\""$(pon_get_voltage)"\",\"tx_packets\":\""$(pon_get_tx_packets)"\",\"rx_packets\":\""$(pon_get_rx_packets)"\",\"tx_bytes\":\""$(pon_get_tx_bytes)"\",\"rx_bytes\":\""$(pon_get_rx_bytes)"\"}"] },
	expect: { '': {} }
});

return L.Class.extend({
	title: _('Optical Module Information'),

	load: function() {
		return L.resolveDefault(callOpticalData(), {});
	},

	render: function(data) {
		var info = data || {};

		var fields = [
			[_('TX Power (dBm)'), info.tx_power || 'N/A'],
			[_('RX Power (dBm)'), info.rx_power || 'N/A'],
			[_('Temperature (C)'), info.temperature || 'N/A'],
			[_('Bias Current (uA)'), info.bias_current || 'N/A'],
			[_('Supply Voltage (uV)'), info.voltage || 'N/A'],
			[_('TX Packets'), info.tx_packets || '0'],
			[_('RX Packets'), info.rx_packets || '0'],
			[_('TX Bytes'), info.tx_bytes || '0'],
			[_('RX Bytes'), info.rx_bytes || '0']
		];

		var table = E('table', { 'class': 'table' });
		fields.forEach(function(f) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [ E('strong', {}, [f[0]]) ]),
				E('td', { 'class': 'td left' }, [ f[1] ])
			]));
		});

		return E('div', {}, [
			E('h2', {}, [_('Optical Module Information')]),
			E('div', { 'class': 'cbi-section' }, [
				E('div', { 'class': 'section-title' }, [_('SFP/BOSA Optical Parameters')]),
				table
			])
		]);
	}
});
