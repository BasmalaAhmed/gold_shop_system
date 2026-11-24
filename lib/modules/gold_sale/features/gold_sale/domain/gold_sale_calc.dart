enum LaborPricingType { perGram, percentageOfGoldValue, fixed }

class GoldSaleInput {
  const GoldSaleInput({
    required this.grossWeightMg,
    required this.stonesWeightMg,
    required this.karat,
    required this.goldPricePerGramPiasters,
    required this.laborValue,
    required this.laborPricingType,
  });

  final int grossWeightMg;
  final int stonesWeightMg;
  final int karat;

  final int goldPricePerGramPiasters;

  final int laborValue;

  final LaborPricingType laborPricingType;
}

class GoldSaleLineResult {
  const GoldSaleLineResult({
    required this.netWeightMg,
    required this.goldValuePiasters,
    required this.laborBeforeDiscountPiasters,
    required this.discountPiasters,
    required this.laborAfterDiscountPiasters,
    required this.taxPiasters,
    required this.totalPiasters,
  });

  final int netWeightMg;
  final int goldValuePiasters;
  final int laborBeforeDiscountPiasters;
  final int discountPiasters;
  final int laborAfterDiscountPiasters;
  final int taxPiasters;
  final int totalPiasters;
}

class GoldSaleCalc {
  const GoldSaleCalc();

  GoldSaleLineResult calculate(
    GoldSaleInput input, {
    required int discountPercent,
    String? supervisorApprovalNumber,
  }) {
    _validate(input);
    validateDiscount(
      discountPercent: discountPercent,
      supervisorApprovalNumber: supervisorApprovalNumber,
    );

    final netWeightMg = input.grossWeightMg - input.stonesWeightMg;

    final goldValue = _roundHalfUp(
      netWeightMg * input.goldPricePerGramPiasters,
      1000,
    );

    final laborBeforeDiscount = switch (input.laborPricingType) {
      LaborPricingType.perGram => _roundHalfUp(
        netWeightMg * input.laborValue,
        1000,
      ),
      LaborPricingType.percentageOfGoldValue => _roundHalfUp(
        goldValue * input.laborValue,
        100,
      ),
      LaborPricingType.fixed => input.laborValue,
    };

    final discount = _roundHalfUp(laborBeforeDiscount * discountPercent, 100);

    final laborAfterDiscount = laborBeforeDiscount - discount;

    final tax = _roundHalfUp(laborAfterDiscount * 14, 100);

    return GoldSaleLineResult(
      netWeightMg: netWeightMg,
      goldValuePiasters: goldValue,
      laborBeforeDiscountPiasters: laborBeforeDiscount,
      discountPiasters: discount,
      laborAfterDiscountPiasters: laborAfterDiscount,
      taxPiasters: tax,
      totalPiasters: goldValue + laborAfterDiscount + tax,
    );
  }

  void _validate(GoldSaleInput input) {
    if (input.grossWeightMg <= 0) {
      throw ArgumentError('Gross weight must be greater than zero.');
    }
    if (input.stonesWeightMg < 0 ||
        input.stonesWeightMg >= input.grossWeightMg) {
      throw ArgumentError(
        'Stones weight must be zero or more and less than gross weight.',
      );
    }
    if (input.karat <= 0 || input.karat > 24) {
      throw ArgumentError('Karat must be between 1 and 24.');
    }
    if (input.goldPricePerGramPiasters <= 0) {
      throw ArgumentError('Gold price must be greater than zero.');
    }
    if (input.laborValue < 0) {
      throw ArgumentError('Labor value cannot be negative.');
    }
  }

  void validateDiscount({
    required int discountPercent,
    String? supervisorApprovalNumber,
  }) {
    if (discountPercent < 0 || discountPercent > 100) {
      throw ArgumentError('Discount percent must be between 0 and 100.');
    }

    if (discountPercent > 10 &&
        (supervisorApprovalNumber == null ||
            supervisorApprovalNumber.trim().isEmpty)) {
      throw ArgumentError(
        'Supervisor approval number is required for discounts above 10%.',
      );
    }
  }

  int _roundHalfUp(int numerator, int denominator) {
    return (numerator + denominator ~/ 2) ~/ denominator;
  }
}
