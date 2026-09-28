import 'package:flutter/material.dart';

import '../state/wallet_store.dart';
import '../utils/format.dart';
import '../widgets/transaction_tile.dart';
import 'bills_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the bottom navigation tab (1 = Activity, 2 = Cards, 3 = Profile).
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _showMore() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void go(int tab) {
          Navigator.pop(sheetContext);
          widget.onNavigate(tab);
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('All transactions'),
                onTap: () => go(1),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Manage cards'),
                onTap: () => go(2),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Security & PIN'),
                onTap: () => go(3),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = WalletScope.of(context);
    final recent = store.transactions.take(5).toList();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinPay', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You're all caught up")),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(_greeting, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            store.userName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _BalanceCard(
            balance: _hideBalance ? '$currencyCode ••••••' : formatMoney(store.balanceCents),
            account: maskAccount(store.accountNumber),
            hidden: _hideBalance,
            onToggle: () => setState(() => _hideBalance = !_hideBalance),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Income this month',
                  value: formatMoney(store.incomeThisMonthCents),
                  icon: Icons.south_west,
                  color: incomeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Spent this month',
                  value: formatMoney(store.expenseThisMonthCents),
                  icon: Icons.north_east,
                  color: expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: Icons.send,
                title: 'Send',
                onTap: () => _open(const SendScreen()),
              ),
              _ActionButton(
                icon: Icons.download,
                title: 'Receive',
                onTap: () => _open(const ReceiveScreen()),
              ),
              _ActionButton(
                icon: Icons.receipt_long,
                title: 'Bills',
                onTap: () => _open(const BillsScreen()),
              ),
              _ActionButton(
                icon: Icons.more_horiz,
                title: 'More',
                onTap: _showMore,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Recent Transactions',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate(1),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No transactions yet', style: textTheme.bodyMedium),
            ),
          for (final tx in recent) TransactionTile(transaction: tx),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.account,
    required this.hidden,
    required this.onToggle,
  });

  final String balance;
  final String account;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6BFF), Color(0xFF0A3FB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              IconButton(
                tooltip: hidden ? 'Show balance' : 'Hide balance',
                visualDensity: VisualDensity.compact,
                onPressed: onToggle,
                icon: Icon(
                  hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              balance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(account, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: colors.primaryContainer,
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
