import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/transaction_tile.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.transaction, this.message});

  final Transaction transaction;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: incomeColor,
                foregroundColor: Colors.white,
                child: Icon(Icons.check, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                message ?? 'Payment successful',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(tx.amountCents),
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DetailRow(label: 'Description', value: tx.title),
                      if (tx.counterparty != null)
                        DetailRow(label: 'Details', value: tx.counterparty!),
                      if (tx.note != null) DetailRow(label: 'Note', value: tx.note!),
                      DetailRow(
                        label: 'Date',
                        value: '${formatDate(tx.date)}, ${formatTime(tx.date)}',
                      ),
                      DetailRow(label: 'Reference', value: tx.reference),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
