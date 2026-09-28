import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintech_app/main.dart';
import 'package:fintech_app/state/wallet_store.dart';

void main() {
  late WalletStore store;

  setUp(() => store = WalletStore.inMemory());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FinPayApp(store: store));
  }

  testWidgets('Displays the FinPay dashboard', (tester) async {
    await pumpApp(tester);

    expect(find.text('FinPay'), findsOneWidget);
    expect(find.text('Sasuni'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('LKR 245,750.00'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
  });

  testWidgets('Hides and shows the balance', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pump();
    expect(find.text('LKR 245,750.00'), findsNothing);

    await tester.tap(find.byTooltip('Show balance'));
    await tester.pump();
    expect(find.text('LKR 245,750.00'), findsOneWidget);
  });

  testWidgets('Sends money to a saved payee after PIN confirmation',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nimal'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('amountField')), '5000');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm transfer'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('pinField')), '1234');
    await tester.pumpAndSettle();

    expect(find.text('Money sent'), findsOneWidget);
    expect(store.balanceCents, 24575000 - 500000);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 240,750.00'), findsOneWidget);
    expect(find.text('To Nimal Perera'), findsOneWidget);
  });

  testWidgets('Rejects a transfer above the balance', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nameField')), 'Test User');
    await tester.enterText(find.byKey(const Key('accountField')), '99998888');
    await tester.enterText(find.byKey(const Key('amountField')), '999999');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    expect(find.text('Insufficient balance'), findsOneWidget);
    expect(find.text('Confirm transfer'), findsNothing);
    expect(store.balanceCents, 24575000);
  });

  testWidgets('Wrong PIN does not move money', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nimal'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('amountField')), '100');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pinField')), '0000');
    await tester.pumpAndSettle();
    expect(find.textContaining('Incorrect PIN'), findsOneWidget);
    expect(store.balanceCents, 24575000);
  });

  testWidgets('Activity tab filters transactions', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    final activity = find.byType(ListView).last;
    expect(find.descendant(of: activity, matching: find.text('Salary')), findsOneWidget);
    expect(find.descendant(of: activity, matching: find.text('Coffee')), findsNothing);
  });
}
