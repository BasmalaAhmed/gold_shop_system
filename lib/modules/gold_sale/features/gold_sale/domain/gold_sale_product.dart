import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'gold_item_status.dart';

class GoldSaleProduct {
  const GoldSaleProduct({
    required this.code,
    required this.status,
    required this.grossWeightMg,
    required this.stonesWeightMg,
    required this.karat,
    this.name = 'قطعة ذهب',
    this.defaultLaborValue = 0,
    this.defaultLaborType = LaborPricingType.perGram,
    this.defaultDiscountPercent = 0,
  });

  final String code;
  final GoldItemStatus status;
  final int grossWeightMg;
  final int stonesWeightMg;
  final int karat;
  final String name;
  final int defaultLaborValue;
  final LaborPricingType defaultLaborType;
  final int defaultDiscountPercent;

  GoldSaleProduct copyWith({GoldItemStatus? status}) {
    return GoldSaleProduct(
      code: code,
      status: status ?? this.status,
      grossWeightMg: grossWeightMg,
      stonesWeightMg: stonesWeightMg,
      karat: karat,
      name: name,
      defaultLaborValue: defaultLaborValue,
      defaultLaborType: defaultLaborType,
      defaultDiscountPercent: defaultDiscountPercent,
    );
  }
}
