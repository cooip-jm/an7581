'use strict';
'require baseclass';
'require form';
'require uci';

return baseclass.extend({
	title: _('OLT Authentication'),

	load: function() {
		return L.resolveDefault(uci.load('pon_auth'), null);
	},

	render: function() {
		var m, s, o;

		m = new form.Map('pon_auth', _('OLT Authentication'),
			_('Configure ONT serial number and password for OLT authentication.'));

		s = m.section(form.TypedSection, 'slid', _('SLID / Password Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable Password Authentication'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'value', _('ONT Password (SLID)'),
			_('Password for OLT authentication. ASCII: max 10 characters. HEX: max 20 hex digits.'));
		o.datatype = 'maxlength(20)';
		o.rmempty = true;
		o.password = true;

		o = s.option(form.ListValue, 'mode', _('SLID Format'));
		o.value('ascii', _('ASCII Mode (max 10 characters)'));
		o.value('hex', _('HEX Mode (max 20 hex digits)'));
		o.default = 'ascii';
		o.rmempty = false;

		s = m.section(form.TypedSection, 'loid', _('LOID / Logical ID Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable LOID Authentication'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'value', _('Logical ID'),
			_('Logic Identifier for OLT registration. Max 24 characters.'));
		o.datatype = 'maxlength(24)';
		o.rmempty = true;

		o = s.option(form.Value, 'password', _('LOID Password'));
		o.datatype = 'maxlength(12)';
		o.rmempty = true;
		o.password = true;

		s = m.section(form.TypedSection, 'password', _('Direct Password Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Value, 'value', _('ONT Password'));
		o.datatype = 'maxlength(20)';
		o.rmempty = true;
		o.password = true;

		return m.render();
	}
});
