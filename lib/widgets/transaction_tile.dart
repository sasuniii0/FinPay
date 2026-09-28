import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../utils/format.dart';

const incomeColor = Color(0xFF1B9E4B);
const expenseColor = Color(0xFFD93A3A);

String signedAmount(Transaction tx) =>
    '${tx.isIncome ? '+' : '-'} ${formatMoney(tx.amountCents)}';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => showTransactionDetails(context, tx),
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Icon(tx.category.icon),
      ),
      title: Text(
        tx.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatDayTime(tx.date)),
      trailing: Text(
        signedAmount(tx),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: tx.isIncome ? incomeColor : expenseColor,
        ),
      ),
    );
  }
}

Future<void> showTransactionDetails(BuildContext context, Transaction tx) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 28, child: Icon(tx.category.icon, size: 28)),
              const SizedBox(height: 12),
              Text(tx.title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                signedAmount(tx),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tx.isIncome ? incomeColor : expenseColor,
                ),
              ),
              const SizedBox(height: 20),
              DetailRow(label: 'Status', value: 'Completed'),
              DetailRow(label: 'Category', value: tx.category.label),
              DetailRow(
                label: 'Date',
                value: '${formatDate(tx.date)}, ${formatTime(tx.date)}',
              ),
              if (tx.counterparty != null)
                DetailRow(label: 'Details', value: tx.counterparty!),
              if (tx.note != null) DetailRow(label: 'Note', value: tx.note!),
              DetailRow(
                label: 'Reference',
                value: tx.reference,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: tx.reference));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reference copied')),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: TextStyle(color: muted))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (onCopy != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: onCopy,
                child: Icon(Icons.copy, size: 18, color: muted),
              ),
            ),
        ],
      ),
    );
  }
}
