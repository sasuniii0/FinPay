import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/wallet_store.dart';
import '../utils/format.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _toast(BuildContext context, String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _editName(BuildContext context, WalletStore store) async {
    final controller = TextEditingController(text: store.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      await store.updateName(name);
      if (context.mounted) _toast(context, 'Name updated');
    } on WalletException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _changePin(BuildContext context, WalletStore store) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePinDialog(store: store),
    );
    if (changed == true && context.mounted) _toast(context, 'PIN changed');
  }

  Future<void> _reset(BuildContext context, WalletStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'This restores the starting balance, transactions, payees, cards '
          'and the default PIN (1234).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.resetDemoData();
    if (context.mounted) _toast(context, 'Demo data restored');
  }

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    final colors = Theme.of(context).colorScheme;
    final initials = store.userName.isEmpty ? '?' : store.userName[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colors.primaryContainer,
              child: Text(initials, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              store.userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Center(child: Text('Account ${maskAccount(store.accountNumber)}')),
          const SizedBox(height: 20),
          const _Header('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Display name'),
            subtitle: Text(store.userName),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editName(context, store),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Account number'),
            subtitle: Text(store.accountNumber),
            trailing: const Icon(Icons.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: store.accountNumber));
              _toast(context, 'Account number copied');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Saved payees'),
            subtitle: Text('${store.payees.length} saved'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _PayeesScreen()),
            ),
          ),
          const _Header('Security'),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Change PIN'),
            subtitle: const Text('Used to approve payments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _changePin(context, store),
          ),
          const _Header('App'),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset demo data'),
            onTap: () => _reset(context, store),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'FinPay',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Demo wallet – no real money is moved.',
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _ChangePinDialog extends StatefulWidget {
  const _ChangePinDialog({required this.store});

  final WalletStore store;

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _pinField(TextEditingController c, String label, {FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: c,
      obscureText: true,
      maxLength: 4,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: validator ?? (v) => (v?.length ?? 0) != 4 ? 'Enter 4 digits' : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.store.changePin(currentPin: _current.text, newPin: _next.text);
      if (mounted) Navigator.pop(context, true);
    } on WalletException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change PIN'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pinField(_current, 'Current PIN'),
            _pinField(_next, 'New PIN'),
            _pinField(
              _confirm,
              'Confirm new PIN',
              validator: (v) => v != _next.text ? 'PINs do not match' : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _PayeesScreen extends StatelessWidget {
  const _PayeesScreen();

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    final payees = store.payees;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved payees')),
      body: payees.isEmpty
          ? const Center(child: Text('No saved payees'))
          : ListView(
              children: [
                for (final p in payees)
                  ListTile(
                    leading: CircleAvatar(child: Text(p.initials)),
                    title: Text(p.name),
                    subtitle: Text('${p.bank} · ${p.accountNumber}'),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await store.removePayee(p);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${p.name} removed')),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
