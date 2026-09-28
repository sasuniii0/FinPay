import 'package:flutter/material.dart';

enum TxCategory {
  salary('Salary', Icons.work_outline),
  transfer('Transfer', Icons.send_outlined),
  deposit('Deposit', Icons.account_balance_wallet_outlined),
  bills('Bills', Icons.receipt_long_outlined),
  food('Food & Drinks', Icons.local_cafe_outlined),
  shopping('Shopping', Icons.shopping_bag_outlined);

  const TxCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.isIncome,
    required this.date,
    required this.reference,
    this.counterparty,
    this.note,
  });

  final String id;
  final String title;
  final TxCategory category;

  /// Always positive; direction is given by [isIncome].
  final int amountCents;
  final bool isIncome;
  final DateTime date;
  final String reference;
  final String? counterparty;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'amountCents': amountCents,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'reference': reference,
        'counterparty': counterparty,
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        title: json['title'] as String,
        category: TxCategory.values.byName(json['category'] as String),
        amountCents: json['amountCents'] as int,
        isIncome: json['isIncome'] as bool,
        date: DateTime.parse(json['date'] as String),
        reference: json['reference'] as String,
        counterparty: json['counterparty'] as String?,
        note: json['note'] as String?,
      );
}

class Payee {
  const Payee({
    required this.name,
    required this.accountNumber,
    required this.bank,
  });

  final String name;
  final String accountNumber;
  final String bank;

  String get initials => name
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Map<String, dynamic> toJson() =>
      {'name': name, 'accountNumber': accountNumber, 'bank': bank};

  factory Payee.fromJson(Map<String, dynamic> json) => Payee(
        name: json['name'] as String,
        accountNumber: json['accountNumber'] as String,
        bank: json['bank'] as String,
      );
}

class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.label,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.monthlyLimitCents,
    this.isFrozen = false,
  });

  final String id;
  final String label;
  final String number;
  final String expiry;
  final String cvv;
  final int monthlyLimitCents;
  final bool isFrozen;

  String get last4 => number.substring(number.length - 4);

  PaymentCard copyWith({bool? isFrozen, int? monthlyLimitCents}) => PaymentCard(
        id: id,
        label: label,
        number: number,
        expiry: expiry,
        cvv: cvv,
        monthlyLimitCents: monthlyLimitCents ?? this.monthlyLimitCents,
        isFrozen: isFrozen ?? this.isFrozen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'number': number,
        'expiry': expiry,
        'cvv': cvv,
        'monthlyLimitCents': monthlyLimitCents,
        'isFrozen': isFrozen,
      };

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
        id: json['id'] as String,
        label: json['label'] as String,
        number: json['number'] as String,
        expiry: json['expiry'] as String,
        cvv: json['cvv'] as String,
        monthlyLimitCents: json['monthlyLimitCents'] as int,
        isFrozen: json['isFrozen'] as bool,
      );
}

class Biller {
  const Biller(this.name, this.icon, this.refLabel);

  final String name;
  final IconData icon;

  /// What the customer reference is called, e.g. "Account number".
  final String refLabel;

  static const all = [
    Biller('Electricity', Icons.bolt_outlined, 'Electricity account no.'),
    Biller('Water', Icons.water_drop_outlined, 'Water account no.'),
    Biller('Mobile', Icons.smartphone_outlined, 'Mobile number'),
    Biller('Internet', Icons.wifi, 'Internet account no.'),
    Biller('Television', Icons.tv_outlined, 'Subscriber ID'),
    Biller('Insurance', Icons.health_and_safety_outlined, 'Policy number'),
  ];
}
