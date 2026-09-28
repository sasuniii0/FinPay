import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/wallet_store.dart';

/// Asks the user for their 4-digit PIN. Resolves to true only when the PIN
/// is verified; false if cancelled or after too many wrong attempts.
Future<bool> confirmWithPin(
  BuildContext context, {
  required String title,
  required String summary,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinDialog(
      title: title,
      summary: summary,
      store: WalletScope.read(context),
    ),
  );
  return result ?? false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.title,
    required this.summary,
    required this.store,
  });

  final String title;
  final String summary;
  final WalletStore store;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  static const _maxAttempts = 3;

  final _controller = TextEditingController();
  String? _error;
  int _attempts = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.store.verifyPin(_controller.text)) {
      Navigator.pop(context, true);
      return;
    }
    _attempts++;
    if (_attempts >= _maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Too many wrong attempts. Try again later.')),
      );
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _error = 'Incorrect PIN (${_maxAttempts - _attempts} attempts left)';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.summary),
          const SizedBox(height: 16),
          TextField(
            key: const Key('pinField'),
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 10),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Enter PIN',
              errorText: _error,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.length == 4) _submit();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
