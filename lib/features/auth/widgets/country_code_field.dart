import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/tokens.dart';

const _codes = [
  ('+1', 'US/CA'),
  ('+44', 'UK'),
  ('+91', 'IN'),
  ('+61', 'AU'),
  ('+49', 'DE'),
  ('+33', 'FR'),
  ('+81', 'JP'),
  ('+55', 'BR'),
  ('+27', 'ZA'),
  ('+971', 'AE'),
];

/// Phone input with a country-code selector.
class CountryCodePhoneField extends StatelessWidget {
  const CountryCodePhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    this.label = 'Phone number',
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: countryCode,
            decoration: const InputDecoration(labelText: 'Code'),
            items: [
              for (final (code, region) in _codes)
                DropdownMenuItem(
                  value: code,
                  child: Text('$code $region', overflow: TextOverflow.ellipsis),
                ),
            ],
            selectedItemBuilder: (context) =>
                [for (final (code, _) in _codes) Text(code)],
            onChanged: (v) {
              if (v != null) onCountryChanged(v);
            },
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
            ],
            decoration: InputDecoration(labelText: label),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 7 ? 'Enter a valid phone number' : null;
            },
          ),
        ),
      ],
    );
  }
}
