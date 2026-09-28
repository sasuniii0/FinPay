import 'package:flutter/material.dart';

void main() {
  runApp(const FinPayApp());
}

class FinPayApp extends StatelessWidget {
  const FinPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinPay',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FinPay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Good Morning 👋',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Sasuni',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.blue,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'LKR 245,750.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    '**** 4582',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                _ActionButton(
                  icon: Icons.send,
                  title: 'Send',
                  onTap: () {},
                ),

                _ActionButton(
                  icon: Icons.download,
                  title: 'Receive',
                  onTap: () {},
                ),

                _ActionButton(
                  icon: Icons.receipt_long,
                  title: 'Bills',
                  onTap: () {},
                ),

                _ActionButton(
                  icon: Icons.more_horiz,
                  title: 'More',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _TransactionItem(
              icon: Icons.work_outline,
              title: 'Salary',
              date: 'Today, 09:30 AM',
              amount: '+ LKR 70,000',
              isIncome: true,
            ),

            _TransactionItem(
              icon: Icons.local_cafe_outlined,
              title: 'Coffee',
              date: 'Today, 08:15 AM',
              amount: '- LKR 850',
              isIncome: false,
            ),

            _TransactionItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Shopping',
              date: 'Yesterday',
              amount: '- LKR 4,500',
              isIncome: false,
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Transfer',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


// Quick Action Button

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.blue.shade50,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}


// Transaction Item

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final bool isIncome;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        child: Icon(icon),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(date),

      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}