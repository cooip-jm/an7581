'use strict';
'require view';
'require form';
'require uci';

return view.extend({
	title: _('PON Configuration'),

	load: function() {
		return Promise.all([
			L.resolveDefault(uci.load('pon'), null),
			L.resolveDefault(uci.load('pon_auth'), null)
		]);
	},

	render: function() {
		var m, s, o;

		m = new form.Map('pon', _('PON Configuration'),
			_('Configure PON hardware parameters for the Nokia XG-040G-MD (AN7581).'));

		s = m.section(form.TypedSection, 'global', _('Global Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable PON Subsystem'),
			_('Start the PON driver stack, BOSA transceiver, and management daemons on boot.'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.ListValue, 'pon_mode', _('PON Mode'),
			_('Select the PON protocol. Auto-detect is recommended.'));
		o.value('auto', _('Auto-detect'));
		o.value('gpon', _('GPON (ITU-T G.984)'));
		o.value('epon', _('EPON (IEEE 802.3ah)'));
		o.value('xgspon', _('XGS-PON (ITU-T G.9807.1)'));
		o.default = 'auto';
		o.readonly = true;

		o = s.option(form.ListValue, 'bosa_chip', _('BOSA Transceiver Chip'));
		o.value('en7572', _('EN7572 (internal)'));
		o.value('gn25l98', _('GN25L98'));
		o.value('gn28l96', _('GN28L96'));
		o.value('ux3320', _('UX3320'));
		o.default = 'en7572';
		o.readonly = true;

		s = m.section(form.TypedSection, 'global', _('FEC Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'fec_rx', _('RX FEC (Downstream)'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.Flag, 'fec_tx', _('TX FEC (Upstream)'));
		o.default = '1';
		o.rmempty = false;

		s = m.section(form.TypedSection, 'global', _('Diagnostics'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'event_debug', _('Enable PON Debug Logging'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Flag, 'init_report', _('Enable O1 Init Report'));
		o.default = '1';
		o.rmempty = false;

		s = m.section(form.TypedSection, 'omci', _('OMCI Settings'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable OMCI Manager'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.ListValue, 'pm_flag', _('Performance Monitor'));
		o.value('0', _('Disabled'));
		o.value('1', _('Enabled'));
		o.default = '0';

		/* ── PON VLAN ────────────────────────────────────── */
		s = m.section(form.TypedSection, 'pon_vlan', _('PON VLAN'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable VLAN Tagging'),
			_('Configure VLAN tag handling on the PON interface.'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.ListValue, 'mode', _('VLAN Mode'));
		o.value('transparent', _('Transparent (no VLAN processing)'));
		o.value('tag', _('Tag (add/replace VLAN tag)'));
		o.value('translate', _('Translate (rewrite VLAN tag)'));
		o.default = 'transparent';
		o.rmempty = false;

		o = s.option(form.Value, 'vid', _('VLAN ID'),
			_('VLAN identifier (1-4094). Required for tag and translate modes.'));
		o.datatype = 'range(1,4094)';
		o.rmempty = true;
		o.placeholder = '100';

		o = s.option(form.ListValue, 'priority', _('VLAN Priority'),
			_('802.1p priority (0-7).'));
		for (var p = 0; p <= 7; p++)
			o.value(String(p), String(p));
		o.default = '0';
		o.rmempty = false;

		return m.render();
	}
});
