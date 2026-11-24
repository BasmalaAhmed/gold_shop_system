import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/conflict_review_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/sync_operation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SyncOperation _op({
  String syncStatus = 'pending',
  bool outcomeUnknown = false,
  bool alreadyProcessed = false,
  DateTime? confirmedAt,
  int? conflictServerBalance,
  String? otherDevice,
  int? otherAmount,
}) {
  return SyncOperation(
    operationId: 'op-1',
    paymentId: 'pay-1',
    customerId: 'customer-001',
    deviceId: 'a7-device',
    deviceSequence: 12,
    amount: 120000,
    paymentStatus: syncStatus,
    syncStatus: syncStatus,
    createdAt: DateTime.utc(2026, 11, 24, 9, 2),
    lastError: null,
    outcomeUnknown: outcomeUnknown,
    alreadyProcessed: alreadyProcessed,
    confirmedAt: confirmedAt,
    conflictServerBalance: conflictServerBalance,
    conflictOtherDevice: otherDevice,
    conflictOtherAmount: otherAmount,
    conflictOtherAt: otherDevice == null
        ? null
        : DateTime.utc(2026, 11, 24, 8, 45),
  );
}

Widget _wrap(Widget child) => MaterialApp(
  builder: (context, c) =>
      Directionality(textDirection: TextDirection.rtl, child: c!),
  home: Scaffold(body: child),
);

void main() {
  test('uiState maps queue rows to UI states', () {
    expect(_op().uiState, OpUiState.pending);
    expect(_op(outcomeUnknown: true).uiState, OpUiState.verifying);
    expect(_op(syncStatus: 'syncing').uiState, OpUiState.syncing);
    expect(_op(syncStatus: 'conflict').uiState, OpUiState.conflict);
    expect(_op(syncStatus: 'confirmed').uiState, OpUiState.confirmed);
  });

  test('displayId uses device label and padded sequence', () {
    expect(_op().displayId, 'OP-A7-0012');
  });

  testWidgets('conflict card shows server balance', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SyncOperationCard(
          operation: _op(syncStatus: 'conflict', conflictServerBalance: 100000),
        ),
      ),
    );

    expect(find.text('تعارض'), findsOneWidget);
    expect(find.textContaining('1,000.00 ج.م فقط'), findsOneWidget);
  });

  testWidgets('verifying card promises no duplicate', (tester) async {
    await tester.pumpWidget(
      _wrap(SyncOperationCard(operation: _op(outcomeUnknown: true))),
    );

    expect(find.text('جارٍ التأكد'), findsOneWidget);
    expect(find.textContaining('ولن تُسجَّل مرتين'), findsOneWidget);
  });

  testWidgets('already processed card explains single collection', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SyncOperationCard(
          operation: _op(
            syncStatus: 'confirmed',
            alreadyProcessed: true,
            confirmedAt: DateTime.utc(2026, 11, 24, 9, 25),
          ),
        ),
      ),
    );

    expect(find.text('تم'), findsOneWidget);
    expect(find.textContaining('تحصيل واحد فقط دون تكرار'), findsOneWidget);
  });

  testWidgets('conflict review shows amounts, reason and keeps the op', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, c) =>
            Directionality(textDirection: TextDirection.rtl, child: c!),
        home: ConflictReviewView(
          operation: _op(
            syncStatus: 'conflict',
            conflictServerBalance: 100000,
            otherDevice: 'B2',
            otherAmount: 50000,
          ),
          repository: PaymentRepo(database: AppDatabase.instance),
          api: MockDebtApi(),
          network: MockNetwork(),
        ),
      ),
    );

    expect(
      find.text('المبلغ الذي سجّلته أكبر من المتبقي على الخادم'),
      findsOneWidget,
    );
    expect(find.text('1,200.00 ج.م'), findsOneWidget);
    expect(find.text('1,000.00 ج.م'), findsOneWidget);
    expect(find.text('200.00 ج.م'), findsOneWidget);
    expect(find.textContaining('B2'), findsOneWidget);
    expect(find.textContaining('لم نحذف العملية'), findsOneWidget);
    expect(find.text('تعديل المبلغ إلى 1,000.00'), findsOneWidget);
    expect(find.text('إلغاء التحصيل'), findsOneWidget);
    expect(find.text('تأجيل المراجعة'), findsOneWidget);
  });

  test('cancelled and superseded rows map to their own UI states', () {
    expect(_op(syncStatus: 'cancelled').uiState, OpUiState.cancelled);
    expect(_op(syncStatus: 'superseded').uiState, OpUiState.superseded);
  });
}
