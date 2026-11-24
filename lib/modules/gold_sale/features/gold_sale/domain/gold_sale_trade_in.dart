int roundHalfUp(int numerator, int denominator) =>
    (numerator + denominator ~/ 2) ~/ denominator;

const List<int> supportedKarats = [24, 21, 18];

class TradeInInput {
  const TradeInInput({
    required this.weightMg,
    required this.karat,
    required this.buyPricePerGramPiasters,
    this.deductionBasisPoints = 0,
  });

  final int weightMg;
  final int karat;
  final int buyPricePerGramPiasters;
  final int deductionBasisPoints;
}

class TradeInResult {
  const TradeInResult({
    this.weightAfterDeductionMg = 0,
    required this.deductionPiasters,
    required this.valuePiasters,
    required this.goldValuePiasters,
  });
  final int weightAfterDeductionMg;
  final int goldValuePiasters;
  final int deductionPiasters;
  final int valuePiasters;
}

class TradeInCalc {
  const TradeInCalc();

  TradeInResult calculate(TradeInInput input) {
    if (input.weightMg <= 0) {
      throw ArgumentError('Trade-in weight must be greater than zero.');
    }
    if (!supportedKarats.contains(input.karat)) {
      throw ArgumentError('Karat must be one of $supportedKarats.');
    }
    if (input.buyPricePerGramPiasters <= 0) {
      throw ArgumentError('Buy price must be greater than zero.');
    }
    if (input.deductionBasisPoints < 0 || input.deductionBasisPoints >= 10000) {
      throw ArgumentError('Deduction must be at least 0 and below 100%.');
    }

    final weightAfterDeductionMg = roundHalfUp(
      input.weightMg * (10000 - input.deductionBasisPoints),
      10000,
    );

    final value = roundHalfUp(
      weightAfterDeductionMg * input.buyPricePerGramPiasters,
      1000,
    );

    final goldValue = roundHalfUp(
      input.weightMg * input.buyPricePerGramPiasters,
      1000,
    );

    final deduction = goldValue - value;

    return TradeInResult(
      weightAfterDeductionMg: weightAfterDeductionMg,
      deductionPiasters: deduction,
      valuePiasters: value,
      goldValuePiasters: goldValue,
    );
  }
}
