'use strict';
'require baseclass';
'require rpc';

var callLuciNetworkDevices = rpc.declare({
  object: 'luci-rpc',
  method: 'getNetworkDevices',
  expect: { '': {} }
});

var ponNames = ['pon', 'omci', 'gpon0.ani', 'veip0', 'gpon0'];

return baseclass.extend({
  title: _('PON Interfaces'),

  load: function() {
    return callLuciNetworkDevices();
  },

  render: function(devices) {
    var ponDevices = [];

    for (var name in devices) {
      if (ponNames.indexOf(name) >= 0) {
        ponDevices.push(devices[name]);
      }
    }

    if (ponDevices.length === 0) {
      return '';
    }

    var ponTable = E('div', { class: 'network-status-table' });

    for (var i = 0; i < ponDevices.length; i++) {
      var dev = ponDevices[i];
      var active = !!(dev.up && dev.link && dev.link.carrier);
      var icon = L.resource('icons/%s.png'.format(active ? 'ethernet' : 'ethernet_disabled'));

      ponTable.appendChild(
        E('div', { class: 'ifacebox' }, [
          E('div', { class: 'ifacebox-head center ' + (active ? 'active' : '') },
            E('strong', dev.name)),
          E('div', { class: 'ifacebox-body left' }, [
            L.itemlist(E('span'), [
              _('Type'), 'PON',
              _('State'), active ? _('Connected') : _('Not connected'),
              _('MAC'), dev.mac || '-'
            ]),
            E('div', {},
              renderBadge(icon, null, _('Device'), dev.name, _('MAC'), dev.mac || '-'))
          ])
        ])
      );
    }

    return E([ponTable]);
  }
});
