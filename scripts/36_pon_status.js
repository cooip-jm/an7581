'use strict';
'require baseclass';

return baseclass.extend({
  title: _('Optical / OMCI'),

  load: function() {
    return fetch('/cgi-bin/pon-status')
      .then(function(r) { return r.json(); })
      .catch(function() { return null; });
  },

  render: function(data) {
    var cpuTemp = 'N/A', ponTemp = 'N/A', omci = 'N/A', olt = 'N/A';
    var txPower = 'N/A', rxPower = 'N/A';
    var mfr = 'N/A', model = 'N/A';

    if (data) {
      if (data.cpu_temp_c && data.cpu_temp_c !== 'N/A')
        cpuTemp = data.cpu_temp_c + '°C';
      if (data.bosa_temp_c && data.bosa_temp_c !== 'N/A')
        ponTemp = data.bosa_temp_c + '°C';
      if (data.omci_running)
        omci = (data.omci_running === 'yes') ? _('Running') : _('Stopped');
      if (data.mfr && data.mfr !== 'N/A' && data.model && data.model !== 'N/A')
        olt = data.mfr + ' ' + data.model;
      if (data.tx_power_dbm && data.tx_power_dbm !== 'N/A')
        txPower = data.tx_power_dbm + ' dBm';
      if (data.rx_power_dbm && data.rx_power_dbm !== 'N/A')
        rxPower = data.rx_power_dbm + ' dBm';
    }

    var fields = [
      _('CPU Temperature'), cpuTemp,
      _('PON Temperature'), ponTemp,
      _('TX Power'), txPower,
      _('RX Power'), rxPower,
      _('OMCI Status'), omci,
      _('OLT'), olt
    ];

    var table = E('table', { 'class': 'table' });
    for (var i = 0; i < fields.length; i += 2) {
      table.appendChild(E('tr', { 'class': 'tr' }, [
        E('td', { 'class': 'td left', 'width': '33%' }, [fields[i]]),
        E('td', { 'class': 'td left' }, [fields[i + 1] || 'N/A'])
      ]));
    }

    return table;
  }
});
