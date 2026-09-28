import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/format.dart';

/// Currency input that validates format, positivity and an optional maximum.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.maxCents,
    this.maxMessage = 'Insufficient balance',
    this.label = 'Amount',
  });

  final TextEditingController controller;
  final int? maxCents;
  final String maxMessage;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('amountField'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$currencyCode ',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final cents = parseAmountToCents(value ?? '');
        if (cents == null) return 'Enter a valid amount';
        if (cents <= 0) return 'Amount must be greater than zero';
        if (maxCents != null && cents > maxCents!) return maxMessage;
        return null;
      },
    );
  }
}
