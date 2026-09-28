import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fintech_app/models/models.dart';
import 'package:fintech_app/state/wallet_store.dart';
import 'package:fintech_app/utils/format.dart';

void main() {
  group('format', () {
    test('formatMoney groups thousands and keeps cents', () {
      expect(formatMoney(24575000), 'LKR 245,750.00');
      expect(formatMoney(5), 'LKR 0.05');
      expect(formatMoney(-123456789), '-LKR 1,234,567.89');
    });

    test('parseAmountToCents', () {
      expect(parseAmountToCents('1,250.5'), 125050);
      expect(parseAmountToCents('10'), 1000);
      expect(parseAmountToCents('0.99'), 99);
      expect(parseAmountToCents('1.999'), isNull);
      expect(parseAmountToCents('abc'), isNull);
      expect(parseAmountToCents(''), isNull);
    });
  });

  group('WalletStore', () {
    late WalletStore store;

    setUp(() => store = WalletStore.inMemory());

    test('sendMoney debits balance, records tx and saves payee', () async {
      final tx = await store.sendMoney(
        name: 'Amal',
        accountNumber: '12345678',
        bank: 'City Bank',
        amountCents: 100000,
        savePayee: true,
      );
      expect(store.balanceCents, 24575000 - 100000);
      expect(store.transactions.first.id, tx.id);
      expect(tx.isIncome, isFalse);
      expect(store.payees.any((p) => p.accountNumber == '12345678'), isTrue);
    });

    test('sendMoney rejects insufficient funds and own account', () async {
      expect(
        () => store.sendMoney(
            name: 'X', accountNumber: '12345678', bank: 'B', amountCents: 99999999),
        throwsA(isA<WalletException>()),
      );
      expect(
        () => store.sendMoney(
            name: 'X', accountNumber: store.accountNumber, bank: 'B', amountCents: 100),
        throwsA(isA<WalletException>()),
      );
      expect(store.balanceCents, 24575000);
    });

    test('payBill and addMoney update balance', () async {
      await store.payBill(
          biller: Biller.all.first, reference: '123456', amountCents: 50000);
      await store.addMoney(amountCents: 20000, source: 'Cash deposit');
      expect(store.balanceCents, 24575000 - 50000 + 20000);
    });

    test('changePin validates current and new PIN', () async {
      expect(
        () => store.changePin(currentPin: '0000', newPin: '5678'),
        throwsA(isA<WalletException>()),
      );
      expect(
        () => store.changePin(currentPin: '1234', newPin: '12'),
        throwsA(isA<WalletException>()),
      );
      await store.changePin(currentPin: '1234', newPin: '5678');
      expect(store.verifyPin('5678'), isTrue);
    });

    test('card freeze and limit', () async {
      final id = store.cards.first.id;
      await store.setCardFrozen(id, true);
      await store.setCardLimit(id, 1000000);
      expect(store.cards.first.isFrozen, isTrue);
      expect(store.cards.first.monthlyLimitCents, 1000000);
    });

    test('state persists across loads', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await WalletStore.load();
      await first.addMoney(amountCents: 12345, source: 'Cash deposit');
      await first.updateName('Kasun');

      final second = await WalletStore.load();
      expect(second.balanceCents, 24575000 + 12345);
      expect(second.userName, 'Kasun');
      expect(second.transactions.first.title, 'Top up');
    });
  });
}
