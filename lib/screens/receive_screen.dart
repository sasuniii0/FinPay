import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/amount_field.dart';
import '../widgets/transaction_tile.dart';

const _sources = ['Linked bank account', 'Debit card **** 4582', 'Cash deposit'];
const _quickAmounts = [100000, 500000, 1000000, 2500000];

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String _source = _sources.first;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _addMoney() async {
    if (!_formKey.currentState!.validate()) return;
    final store = WalletScope.read(context);
    setState(() => _busy = true);
    try {
      final tx = await store.addMoney(
        amountCents: parseAmountToCents(_amount.text)!,
        source: _source,
      );
      if (!mounted) return;
      _amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${formatMoney(tx.amountCents)} added to your wallet'),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Receive & add money')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Share your account details', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DetailRow(
                    label: 'Name',
                    value: store.userName,
                    onCopy: () => _copy('Name', store.userName),
                  ),
                  DetailRow(
                    label: 'Account',
                    value: store.accountNumber,
                    onCopy: () => _copy('Account number', store.accountNumber),
                  ),
                  const DetailRow(label: 'Bank', value: 'FinPay'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined),
            label: const Text('Copy all details'),
            onPressed: () => _copy(
              'Account details',
              'Name: ${store.userName}\nAccount: ${store.accountNumber}\nBank: FinPay',
            ),
          ),
          const SizedBox(height: 32),
          Text('Add money', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: AmountField(
              controller: _amount,
              maxCents: WalletStore.maxTransferCents,
              maxMessage: 'Maximum top up is ${formatMoney(WalletStore.maxTransferCents)}',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final cents in _quickAmounts)
                ActionChip(
                  label: Text(formatMoney(cents).replaceAll('.00', '')),
                  onPressed: () => _amount.text = (cents ~/ 100).toString(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _source,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'From',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in _sources) DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => _source = v!),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _addMoney,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Add money'),
            ),
          ),
        ],
      ),
    );
  }
}
