import 'package:gold_shop_app/modules/debts_payment/core/allocation_preview.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:flutter_test/flutter_test.dart';

List<DebtBalance> _debts() => [
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
];

void main() {
  test('1200 closes the oldest debt and takes 200 from the second', () {
    final lines = previewAllocation(_debts(), 120000);

    expect(lines, hasLength(2));
    expect(lines[0].debtNumber, 1);
    expect(lines[0].amount, 100000);
    expect(lines[0].closesDebt, isTrue);
    expect(lines[1].debtNumber, 2);
    expect(lines[1].amount, 20000);
    expect(lines[1].closesDebt, isFalse);
  });

  test('partial payment touches only the oldest debt', () {
    final lines = previewAllocation(_debts(), 50000);

    expect(lines, hasLength(1));
    expect(lines.single.amount, 50000);
    expect(lines.single.closesDebt, isFalse);
  });

  test('full balance closes both debts', () {
    final lines = previewAllocation(_debts(), 150000);

    expect(lines.every((l) => l.closesDebt), isTrue);
    expect(lines.fold<int>(0, (t, l) => t + l.amount), 150000);
  });
}