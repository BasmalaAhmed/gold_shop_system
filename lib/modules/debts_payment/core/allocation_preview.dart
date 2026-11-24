import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';

class AllocationLine {
  const AllocationLine({
    required this.debtNumber,
    required this.amount,
    required this.closesDebt,
  });

  final int debtNumber;
  final int amount;
  final bool closesDebt;
}

List<AllocationLine> previewAllocation(List<DebtBalance> debts, int amount) {
  final lines = <AllocationLine>[];
  var left = amount;

  for (var i = 0; i < debts.length && left > 0; i++) {
    final outstanding = debts[i].localOutstanding;
    if (outstanding <= 0) continue;

    final take = left < outstanding ? left : outstanding;
    lines.add(
      AllocationLine(
        debtNumber: i + 1,
        amount: take,
        closesDebt: take == outstanding,
      ),
    );
    left -= take;
  }
  return lines;
}