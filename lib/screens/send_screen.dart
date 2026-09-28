import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/amount_field.dart';
import '../widgets/pin_dialog.dart';
import 'receipt_screen.dart';

const _banks = [
  'FinPay',
  'City Bank',
  'National Savings Bank',
  'Metro Bank',
  'Coastal Bank',
];

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _account = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _bank = _banks.first;
  bool _savePayee = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _account.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectPayee(Payee payee) {
    setState(() {
      _name.text = payee.name;
      _account.text = payee.accountNumber;
      _bank = _banks.contains(payee.bank) ? payee.bank : _banks.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final store = WalletScope.read(context);
    final amount = parseAmountToCents(_amount.text)!;
    final name = _name.text.trim();

    final confirmed = await confirmWithPin(
      context,
      title: 'Confirm transfer',
      summary: 'Send ${formatMoney(amount)} to $name ($_bank · ${_account.text})?',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final tx = await store.sendMoney(
        name: name,
        accountNumber: _account.text,
        bank: _bank,
        amountCents: amount,
        note: _note.text,
        savePayee: _savePayee,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ReceiptScreen(transaction: tx, message: 'Money sent'),
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
    final payees = store.payees;

    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (payees.isNotEmpty) ...[
              Text('Saved payees', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: payees.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) => _PayeeAvatar(
                    payee: payees[i],
                    selected: _account.text == payees[i].accountNumber,
                    onTap: () => _selectPayee(payees[i]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const Key('nameField'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Recipient name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter the recipient name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('accountField'),
              controller: _account,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                labelText: 'Account number',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.length < 8) return 'Account number must be 8–16 digits';
                if (v == store.accountNumber) return 'You cannot send to your own account';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_bank),
              initialValue: _bank,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Bank',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final bank in _banks)
                  DropdownMenuItem(value: bank, child: Text(bank)),
              ],
              onChanged: (v) => setState(() => _bank = v!),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              value: _savePayee,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Save as payee'),
              onChanged: (v) => setState(() => _savePayee = v ?? false),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('sendButton'),
              onPressed: _busy ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayeeAvatar extends StatelessWidget {
  const _PayeeAvatar({
    required this.payee,
    required this.selected,
    required this.onTap,
  });

  final Payee payee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: selected ? colors.primary : colors.primaryContainer,
              foregroundColor: selected ? colors.onPrimary : colors.onPrimaryContainer,
              child: Text(payee.initials),
            ),
            const SizedBox(height: 6),
            Text(
              payee.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
