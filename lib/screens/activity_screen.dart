import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/transaction_tile.dart';

enum _Filter { all, income, expense }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Transaction> _apply(List<Transaction> all) {
    final query = _search.text.trim().toLowerCase();
    return all.where((tx) {
      if (_filter == _Filter.income && !tx.isIncome) return false;
      if (_filter == _Filter.expense && tx.isIncome) return false;
      if (query.isEmpty) return true;
      return tx.title.toLowerCase().contains(query) ||
          tx.category.label.toLowerCase().contains(query) ||
          tx.reference.toLowerCase().contains(query) ||
          (tx.counterparty?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    final items = _apply(store.transactions);

    // Flatten into day headers followed by that day's transactions.
    final rows = <Object>[];
    String? currentDay;
    for (final tx in items) {
      final day = formatDay(tx.date);
      if (day != currentDay) {
        rows.add(day);
        currentDay = day;
      }
      rows.add(tx);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_search.clear),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Filter>(
                segments: const [
                  ButtonSegment(value: _Filter.all, label: Text('All')),
                  ButtonSegment(value: _Filter.income, label: Text('Income')),
                  ButtonSegment(value: _Filter.expense, label: Text('Expenses')),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: rows.isEmpty
                ? const Center(child: Text('No matching transactions'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 4),
                          child: Text(
                            row,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        );
                      }
                      return TransactionTile(transaction: row as Transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
