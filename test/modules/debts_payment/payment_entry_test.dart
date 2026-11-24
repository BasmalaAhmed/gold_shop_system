import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/payment_entry_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: PaymentEntryView(
        customerId: 'customer-001',
        repository: PaymentRepo(database: AppDatabase.instance),
        network: MockNetwork(),
        debts: [
          DebtBalance(
            debtId: 'd1',
            serverOutstanding: 100000,
            localOutstanding: 100000,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          DebtBalance(
            debtId: 'd2',
            serverOutstanding: 50000,
            localOutstanding: 50000,
            createdAt: DateTime.utc(2026, 2, 1),
          ),
        ],
      ),
    );
  }

  Future<void> typeKeys(WidgetTester tester, List<String> keys) async {
    for (final key in keys) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
  }

  testWidgets('amount above the available balance is rejected', (tester) async {
    await tester.pumpWidget(buildScreen());

    await typeKeys(tester, ['1', '6', '0', '0']);

    expect(find.textContaining('أكبر من المتبقي'), findsOneWidget);
    expect(
      tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
      isNull,
    );
  });

  testWidgets('valid amount shows the allocation preview', (tester) async {
    await tester.pumpWidget(buildScreen());

    await typeKeys(tester, ['1', '2', '0', '0']);

    expect(find.text('سيُوزَّع المبلغ كالتالي:'), findsOneWidget);
    expect(find.text('مديونية 1 · تُسدَّد بالكامل ✓'), findsOneWidget);
    expect(find.text('300.00 ج.م'), findsOneWidget);
    expect(
      tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
      isNotNull,
    );
  });
}
