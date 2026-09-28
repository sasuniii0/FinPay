import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class WalletException implements Exception {
  const WalletException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Single source of truth for the wallet: balance, transactions, payees,
/// cards and security settings. Every mutation is persisted locally.
class WalletStore extends ChangeNotifier {
  WalletStore._(this._prefs) {
    _applySeed();
  }

  /// Non-persistent store, useful for tests and previews.
  factory WalletStore.inMemory() => WalletStore._(null);

  static Future<WalletStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final store = WalletStore._(prefs);
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        store._restore(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt or outdated data: fall back to the seeded demo state.
        store._applySeed();
      }
    }
    return store;
  }

  static const _storageKey = 'finpay.wallet.v1';
  static const defaultPin = '1234';
  static const maxTransferCents = 50000000; // LKR 500,000 per transaction

  final SharedPreferences? _prefs;
  final _random = Random();

  late String _userName;
  late String _accountNumber;
  late int _balanceCents;
  late String _pin;
  late List<Transaction> _transactions;
  late List<Payee> _payees;
  late List<PaymentCard> _cards;

  String get userName => _userName;
  String get accountNumber => _accountNumber;
  int get balanceCents => _balanceCents;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Payee> get payees => List.unmodifiable(_payees);
  List<PaymentCard> get cards => List.unmodifiable(_cards);

  int get incomeThisMonthCents => _sumThisMonth(income: true);
  int get expenseThisMonthCents => _sumThisMonth(income: false);

  bool verifyPin(String pin) => pin == _pin;

  // ---------------------------------------------------------------------------
  // Money movement

  Future<Transaction> sendMoney({
    required String name,
    required String accountNumber,
    required String bank,
    required int amountCents,
    String? note,
    bool savePayee = false,
  }) async {
    if (accountNumber == _accountNumber) {
      throw const WalletException('You cannot send money to your own account.');
    }
    if (amountCents > maxTransferCents) {
      throw const WalletException('Amount exceeds the per-transfer limit.');
    }
    _ensureCanDebit(amountCents);

    final tx = _record(
      title: 'To $name',
      category: TxCategory.transfer,
      amountCents: amountCents,
      isIncome: false,
      counterparty: '$bank · $accountNumber',
      note: note,
    );
    if (savePayee && !_payees.any((p) => p.accountNumber == accountNumber)) {
      _payees.add(Payee(name: name, accountNumber: accountNumber, bank: bank));
    }
    await _commit();
    return tx;
  }

  Future<Transaction> payBill({
    required Biller biller,
    required String reference,
    required int amountCents,
  }) async {
    _ensureCanDebit(amountCents);
    final tx = _record(
      title: '${biller.name} bill',
      category: TxCategory.bills,
      amountCents: amountCents,
      isIncome: false,
      counterparty: '${biller.refLabel}: $reference',
    );
    await _commit();
    return tx;
  }

  Future<Transaction> addMoney({
    required int amountCents,
    required String source,
  }) async {
    if (amountCents <= 0) {
      throw const WalletException('Enter an amount greater than zero.');
    }
    final tx = _record(
      title: 'Top up',
      category: TxCategory.deposit,
      amountCents: amountCents,
      isIncome: true,
      counterparty: source,
    );
    await _commit();
    return tx;
  }

  Future<void> removePayee(Payee payee) async {
    _payees.removeWhere((p) => p.accountNumber == payee.accountNumber);
    await _commit();
  }

  // ---------------------------------------------------------------------------
  // Cards

  Future<void> setCardFrozen(String cardId, bool frozen) =>
      _updateCard(cardId, (c) => c.copyWith(isFrozen: frozen));

  Future<void> setCardLimit(String cardId, int limitCents) =>
      _updateCard(cardId, (c) => c.copyWith(monthlyLimitCents: limitCents));

  // ---------------------------------------------------------------------------
  // Profile & security

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const WalletException('Name cannot be empty.');
    _userName = trimmed;
    await _commit();
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!verifyPin(currentPin)) {
      throw const WalletException('Current PIN is incorrect.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      throw const WalletException('PIN must be exactly 4 digits.');
    }
    _pin = newPin;
    await _commit();
  }

  Future<void> resetDemoData() async {
    _applySeed();
    await _commit();
  }

  // ---------------------------------------------------------------------------
  // Internals

  void _ensureCanDebit(int amountCents) {
    if (amountCents <= 0) {
      throw const WalletException('Enter an amount greater than zero.');
    }
    if (amountCents > _balanceCents) {
      throw const WalletException('Insufficient balance.');
    }
  }

  Transaction _record({
    required String title,
    required TxCategory category,
    required int amountCents,
    required bool isIncome,
    String? counterparty,
    String? note,
  }) {
    final now = DateTime.now();
    final tx = Transaction(
      id: '${now.microsecondsSinceEpoch}${_random.nextInt(1000)}',
      title: title,
      category: category,
      amountCents: amountCents,
      isIncome: isIncome,
      date: now,
      reference: _newReference(),
      counterparty: counterparty,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    );
    _balanceCents += isIncome ? amountCents : -amountCents;
    _transactions.insert(0, tx);
    return tx;
  }

  String _newReference() {
    final digits = List.generate(10, (_) => _random.nextInt(10)).join();
    return 'FP$digits';
  }

  Future<void> _updateCard(
    String cardId,
    PaymentCard Function(PaymentCard) update,
  ) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index == -1) throw const WalletException('Card not found.');
    _cards[index] = update(_cards[index]);
    await _commit();
  }

  int _sumThisMonth({required bool income}) {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.isIncome == income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0, (sum, t) => sum + t.amountCents);
  }

  Future<void> _commit() async {
    notifyListeners();
    await _prefs?.setString(_storageKey, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'userName': _userName,
        'accountNumber': _accountNumber,
        'balanceCents': _balanceCents,
        'pin': _pin,
        'transactions': _transactions.map((t) => t.toJson()).toList(),
        'payees': _payees.map((p) => p.toJson()).toList(),
        'cards': _cards.map((c) => c.toJson()).toList(),
      };

  void _restore(Map<String, dynamic> json) {
    _userName = json['userName'] as String;
    _accountNumber = json['accountNumber'] as String;
    _balanceCents = json['balanceCents'] as int;
    _pin = json['pin'] as String;
    _transactions = (json['transactions'] as List)
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _payees = (json['payees'] as List)
        .map((e) => Payee.fromJson(e as Map<String, dynamic>))
        .toList();
    _cards = (json['cards'] as List)
        .map((e) => PaymentCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _applySeed() {
    final now = DateTime.now();
    Transaction seed(
      int id,
      String title,
      TxCategory category,
      int amountCents,
      bool isIncome,
      Duration ago, [
      String? counterparty,
    ]) =>
        Transaction(
          id: 'seed-$id',
          title: title,
          category: category,
          amountCents: amountCents,
          isIncome: isIncome,
          date: now.subtract(ago),
          reference: 'FP${(4815162342 + id * 7919).toString()}',
          counterparty: counterparty,
        );

    _userName = 'Sasuni';
    _accountNumber = '1001234582';
    _balanceCents = 24575000;
    _pin = defaultPin;
    _transactions = [
      seed(1, 'Salary', TxCategory.salary, 7000000, true,
          const Duration(hours: 1), 'Employer payroll'),
      seed(2, 'Coffee', TxCategory.food, 85000, false,
          const Duration(hours: 2), 'Card **** 4582'),
      seed(3, 'Shopping', TxCategory.shopping, 450000, false,
          const Duration(days: 1), 'Card **** 4582'),
      seed(4, 'Electricity bill', TxCategory.bills, 624000, false,
          const Duration(days: 3), 'Electricity account no.: 0412345678'),
      seed(5, 'To Nimal Perera', TxCategory.transfer, 1500000, false,
          const Duration(days: 5), 'City Bank · 2003004005'),
      seed(6, 'Groceries', TxCategory.food, 832000, false,
          const Duration(days: 8), 'Card **** 4582'),
      seed(7, 'Top up', TxCategory.deposit, 2500000, true,
          const Duration(days: 12), 'Linked bank account'),
      seed(8, 'Mobile bill', TxCategory.bills, 149900, false,
          const Duration(days: 20), 'Mobile number: 0771234567'),
    ];
    _payees = const [
      Payee(name: 'Nimal Perera', accountNumber: '2003004005', bank: 'City Bank'),
      Payee(name: 'Kavindi Silva', accountNumber: '3004005006', bank: 'National Savings Bank'),
      Payee(name: 'Ruwan Fernando', accountNumber: '4005006007', bank: 'FinPay'),
    ].toList();
    _cards = [
      const PaymentCard(
        id: 'card-debit',
        label: 'FinPay Debit',
        number: '5412753412344582',
        expiry: '08/29',
        cvv: '321',
        monthlyLimitCents: 15000000,
      ),
      const PaymentCard(
        id: 'card-virtual',
        label: 'Virtual Card',
        number: '4539148803437719',
        expiry: '02/28',
        cvv: '904',
        monthlyLimitCents: 5000000,
      ),
    ];
  }
}

/// Makes the [WalletStore] available to the widget tree and rebuilds
/// dependents whenever it changes.
class WalletScope extends InheritedNotifier<WalletStore> {
  const WalletScope({
    super.key,
    required WalletStore store,
    required super.child,
  }) : super(notifier: store);

  /// Subscribes the calling widget to changes.
  static WalletStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WalletScope>()!.notifier!;

  /// Reads the store without subscribing (use in callbacks).
  static WalletStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WalletScope>()!.notifier!;
}
