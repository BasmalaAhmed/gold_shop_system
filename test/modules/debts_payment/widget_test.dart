import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/customer_debt_view.dart';

void main() {
  testWidgets('shows customer debt balances', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: CustomerDebtView(
          customerId: 'customer-001',
          repository: _FakePaymentRepo(),
          api: MockDebtApi(),
          network: MockNetwork(),
          syncCompleted: const Stream<void>.empty(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('سعاد عبد الرحمن'), findsOneWidget);
    expect(find.text('1,500.00 ج.م'), findsOneWidget);
    expect(find.text('مطابق للخادم'), findsOneWidget);
    expect(find.text('مديونية 1'), findsOneWidget);
    expect(find.text('مديونية 2'), findsOneWidget);
    expect(find.text('تُحصَّل أولاً'), findsOneWidget);
    expect(find.text('تسجيل تحصيل'), findsOneWidget);
  });
}

class _FakePaymentRepo extends PaymentRepo {
  _FakePaymentRepo() : super(database: AppDatabase.instance);

  @override
  Future<List<DebtBalance>> getDebtBalances(String customerId) async {
    return [
      DebtBalance(
        debtId: 'debt-001',
        serverOutstanding: 100000,
        localOutstanding: 100000,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      DebtBalance(
        debtId: 'debt-002',
        serverOutstanding: 50000,
        localOutstanding: 50000,
        createdAt: DateTime.utc(2026, 2, 1),
      ),
    ];
  }

  @override
  Future<List<SyncOperation>> getSyncOperations() async => [];
}
