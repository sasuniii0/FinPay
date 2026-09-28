import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/pin_dialog.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My cards')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: store.cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 28),
        itemBuilder: (context, i) => _CardSection(card: store.cards[i]),
      ),
    );
  }
}

class _CardSection extends StatefulWidget {
  const _CardSection({required this.card});

  final PaymentCard card;

  @override
  State<_CardSection> createState() => _CardSectionState();
}

class _CardSectionState extends State<_CardSection> {
  static const _limitStepCents = 500000; // LKR 5,000
  static const _maxLimitCents = 50000000; // LKR 500,000

  bool _revealed = false;
  double? _draftLimit;

  Future<void> _toggleReveal() async {
    if (_revealed) {
      setState(() => _revealed = false);
      return;
    }
    final ok = await confirmWithPin(
      context,
      title: 'Show card details',
      summary: 'Enter your PIN to view the full card number and CVV.',
    );
    if (ok && mounted) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.read(context);
    final card = widget.card;
    final limit = _draftLimit ?? card.monthlyLimitCents.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CardFace(card: card, revealed: _revealed),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.ac_unit),
          title: const Text('Freeze card'),
          subtitle: Text(card.isFrozen
              ? 'All card payments are blocked'
              : 'Temporarily block card payments'),
          value: card.isFrozen,
          onChanged: (v) async {
            await store.setCardFrozen(card.id, v);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${card.label} ${v ? 'frozen' : 'unfrozen'}'),
            ));
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
          title: Text(_revealed ? 'Hide card details' : 'Show card details'),
          onTap: _toggleReveal,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.speed),
          title: const Text('Monthly spending limit'),
          trailing: Text(
            formatMoney(limit.round()),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Slider(
          value: limit,
          min: _limitStepCents.toDouble(),
          max: _maxLimitCents.toDouble(),
          divisions: _maxLimitCents ~/ _limitStepCents - 1,
          label: formatMoney(limit.round()),
          onChanged: (v) => setState(() => _draftLimit = v),
          onChangeEnd: (v) async {
            await store.setCardLimit(card.id, v.round());
            if (mounted) setState(() => _draftLimit = null);
          },
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.revealed});

  final PaymentCard card;
  final bool revealed;

  String get _number {
    if (!revealed) return '••••  ••••  ••••  ${card.last4}';
    final n = card.number;
    return [for (var i = 0; i < n.length; i += 4) n.substring(i, i + 4)].join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final isVirtual = card.id == 'card-virtual';
    return AspectRatio(
      aspectRatio: 1.586, // ISO/IEC 7810 ID-1
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isVirtual
                    ? const [Color(0xFF6A3DE8), Color(0xFF2E1A87)]
                    : const [Color(0xFF1E6BFF), Color(0xFF0A3FB5)],
              ),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(card.label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.contactless_outlined, color: Colors.white),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_number,
                        style: const TextStyle(fontSize: 20, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Label('EXPIRES', card.expiry),
                      const SizedBox(width: 28),
                      _Label('CVV', revealed ? card.cvv : '•••'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (card.isFrozen)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ac_unit, color: Colors.white),
                    SizedBox(width: 8),
                    Text('FROZEN',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
