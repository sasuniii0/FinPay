import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/amount_field.dart';
import '../widgets/pin_dialog.dart';
import 'receipt_screen.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay bills')),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final biller in Biller.all)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PayBillScreen(biller: biller),
              )),
              child: Ink(
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(biller.icon, size: 30, color: colors.primary),
                    const SizedBox(height: 8),
                    Text(biller.name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PayBillScreen extends StatefulWidget {
  const PayBillScreen({super.key, required this.biller});

  final Biller biller;

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reference.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final store = WalletScope.read(context);
    final amount = parseAmountToCents(_amount.text)!;

    final confirmed = await confirmWithPin(
      context,
      title: 'Confirm payment',
      summary: 'Pay ${formatMoney(amount)} for ${widget.biller.name} '
          '(${_reference.text})?',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final tx = await store.payBill(
        biller: widget.biller,
        reference: _reference.text,
        amountCents: amount,
      );
      if (!mounted) return;
      // Replace both the form and the biller grid with the receipt.
      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
      navigator.push(MaterialPageRoute(
        builder: (_) => ReceiptScreen(transaction: tx, message: 'Bill paid'),
      ));
    } on WalletException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.biller.name} bill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('referenceField'),
              controller: _reference,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration: InputDecoration(
                labelText: widget.biller.refLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Enter at least 6 digits' : null,
            ),
            const SizedBox(height: 16),
            AmountField(controller: _amount, maxCents: store.balanceCents),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Available: ${formatMoney(store.balanceCents)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Pay now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
