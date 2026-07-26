'use strict';
'require view';
'require form';
'require uci';

return view.extend({
	title: _('OLT Authentication'),

	load: function() {
		return L.resolveDefault(uci.load('pon_auth'), null);
	},

	render: function() {
		var m, s, o;

		m = new form.Map('pon_auth', _('OLT Authentication'),
			_('Configure ONT serial number and password for OLT authentication.'));

		/* ── Serial Number (SN) ─────────────────────────── */
		s = m.section(form.TypedSection, 'sn', _('Serial Number (SN)'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Value, 'vendor_id', _('Vendor ID'),
			_('4-byte ASCII vendor identifier (e.g. ALCL, HWTC).'));
		o.datatype = 'maxlength(4)';
		o.rmempty = true;
		o.placeholder = 'ALCL';

		o = s.option(form.Value, 'vssd', _('VSSD (Vendor-Specific Serial)'),
			_('8-byte vendor-specific serial number in hex (8 hex digits). Combined with Vendor ID forms the 12-byte ONT SN.'));
		o.datatype = 'maxlength(8)';
		o.rmempty = true;
		o.placeholder = '00000000';
		o.validate = function(section_id, value) {
			if (value && !/^[0-9a-fA-F]{8}$/.test(value))
				return _('Must be exactly 8 hex digits (0-9, a-f).');
			return true;
		};

		/* ── SLID / Password ────────────────────────────── */
		s = m.section(form.TypedSection, 'slid', _('SLID / Password Authentication'));
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable Password Authentication'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Flag, 'password_disabled', _('Disable Password Transmission'),
			_('When enabled, the ONT will not send the password/PLOAM to the OLT during registration.'));
		o.default = '0';
		o.rmempty = false;

		o = s.option(form.Value, 'value', _('ONT Password (SLID)'),
			_('Password for OLT authentication. ASCII: max 10 characters. HEX: max 20 hex digits.'));
		o.datatype = 'maxlength(20)';
		o.rmempty = true;
		o.password = true;
		o.depends('password_disabled', '0');

		o = s.option(form.ListValue, 'mode', _('SLID Format'));
		o.value('ascii', _('ASCII Mode (max 10 characters)'));
		o.value('hex', _('HEX Mode (max 20 hex digits)'));
		o.default = 'ascii';
		o.rmempty = false;
		o.depends('password_disabled', '0');

		/* ── LOID ───────────────────────────────────────── */
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

		/* ── Direct Password ────────────────────────────── */
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
