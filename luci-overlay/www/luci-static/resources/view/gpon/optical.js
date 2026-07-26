'use strict';
'require view';
'require rpc';

var callOpticalTx = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_tx_power_dbm'] },
	expect: { '': '' }
});
var callOpticalRx = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_rx_power_dbm'] },
	expect: { '': '' }
});
var callOpticalTemp = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_temperature'] },
	expect: { '': '' }
});
var callOpticalBias = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_bias_current'] },
	expect: { '': '' }
});
var callOpticalVolt = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_voltage'] },
	expect: { '': '' }
});
var callOpticalTxPkt = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_tx_packets'] },
	expect: { '': '' }
});
var callOpticalRxPkt = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_rx_packets'] },
	expect: { '': '' }
});
var callOpticalTxByte = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_tx_bytes'] },
	expect: { '': '' }
});
var callOpticalRxByte = rpc.declare({
	object: 'file', method: 'exec',
	params: { command: ['/bin/sh', '-c', '. /usr/libexec/pon_helpers.sh; pon_get_rx_bytes'] },
	expect: { '': '' }
});

return view.extend({
	title: _('Optical Module'),

	load: function() {
		return Promise.all([
			L.resolveDefault(callOpticalTx, ''),
			L.resolveDefault(callOpticalRx, ''),
			L.resolveDefault(callOpticalTemp, ''),
			L.resolveDefault(callOpticalBias, ''),
			L.resolveDefault(callOpticalVolt, ''),
			L.resolveDefault(callOpticalTxPkt, '0'),
			L.resolveDefault(callOpticalRxPkt, '0'),
			L.resolveDefault(callOpticalTxByte, '0'),
			L.resolveDefault(callOpticalRxByte, '0')
		]);
	},

	render: function(data) {
		var vals = data || [];
		for (var i = 0; i < vals.length; i++)
			vals[i] = String(vals[i] || '').trim() || 'N/A';

		var fields = [
			[_('TX Power'), vals[0] !== 'N/A' ? vals[0] + ' dBm' : 'N/A'],
			[_('RX Power'), vals[1] !== 'N/A' ? vals[1] + ' dBm' : 'N/A'],
			[_('Temperature'), vals[2] !== 'N/A' ? vals[2] + ' \u00b0C' : 'N/A'],
			[_('Bias Current'), vals[3] !== 'N/A' ? vals[3] + ' \u00b5A' : 'N/A'],
			[_('Supply Voltage'), vals[4] !== 'N/A' ? vals[4] + ' mV' : 'N/A'],
			[_('TX Packets'), vals[5]],
			[_('RX Packets'), vals[6]],
			[_('TX Bytes'), vals[7]],
			[_('RX Bytes'), vals[8]]
		];

		var table = E('table', { 'class': 'table' });
		fields.forEach(function(f) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, [E('strong', {}, [f[0]])]),
				E('td', { 'class': 'td left' }, [f[1]])
			]));
		});

		return E('div', {}, [
			E('h2', { 'class': 'topic-heading' }, [_('Optical Module')]),
			E('div', { 'class': 'cbi-section' }, [table])
		]);
	}
});
