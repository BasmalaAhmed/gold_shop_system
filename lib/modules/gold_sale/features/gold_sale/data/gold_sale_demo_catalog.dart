import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_product.dart';

class GoldSaleDemoCatalog {
  GoldSaleDemoCatalog();
  final Set<String> _soldCodes = <String>{};

  static const Map<String, GoldSaleProduct> _records = {
    'DEMO-1001': GoldSaleProduct(
      code: 'DEMO-1001',
      name: 'خاتم سوليتير',
      status: GoldItemStatus.available,
      grossWeightMg: 4500,
      stonesWeightMg: 300,
      karat: 21,
      defaultLaborValue: 12000,
      defaultLaborType: LaborPricingType.perGram,
      defaultDiscountPercent: 10,
    ),
    'DEMO-1002': GoldSaleProduct(
      code: 'DEMO-1002',
      name: 'سلسلة كارتير',
      status: GoldItemStatus.available,
      grossWeightMg: 3000,
      stonesWeightMg: 150,
      karat: 18,
      defaultLaborValue: 8000,
      defaultLaborType: LaborPricingType.perGram,
      defaultDiscountPercent: 0,
    ),
    'DEMO-1003': GoldSaleProduct(
      code: 'DEMO-1003',
      name: 'إسورة ذهبية',
      status: GoldItemStatus.reserved,
      grossWeightMg: 5000,
      stonesWeightMg: 500,
      karat: 21,
    ),
    'DEMO-1004': GoldSaleProduct(
      code: 'DEMO-1004',
      name: 'سبيكة ذهبية',
      status: GoldItemStatus.sold,
      grossWeightMg: 4000,
      stonesWeightMg: 0,
      karat: 24,
    ),
    'DEMO-1005': GoldSaleProduct(
      code: 'DEMO-1005',
      name: 'قطعة ورشة',
      status: GoldItemStatus.inWorkshop,
      grossWeightMg: 4000,
      stonesWeightMg: 0,
      karat: 21,
    ),
    'DEMO-1006': GoldSaleProduct(
      code: 'DEMO-1006',
      name: 'قطعة شحن',
      status: GoldItemStatus.inTransit,
      grossWeightMg: 4000,
      stonesWeightMg: 0,
      karat: 18,
    ),

    'G-1042': GoldSaleProduct(
      code: 'G-1042',
      name: 'خاتم سوليتير',
      status: GoldItemStatus.available,
      grossWeightMg: 4500,
      stonesWeightMg: 300,
      karat: 21,
      defaultLaborValue: 12000,
      defaultLaborType: LaborPricingType.perGram,
      defaultDiscountPercent: 10,
    ),
    'G-2207': GoldSaleProduct(
      code: 'G-2207',
      name: 'سلسلة كارتير',
      status: GoldItemStatus.available,
      grossWeightMg: 6250,
      stonesWeightMg: 0,
      karat: 21,
      defaultLaborValue: 35000,
      defaultLaborType: LaborPricingType.fixed,
      defaultDiscountPercent: 0,
    ),
    'G-1180': GoldSaleProduct(
      code: 'G-1180',
      name: 'قطعة ورشة',
      status: GoldItemStatus.inWorkshop,
      grossWeightMg: 4000,
      stonesWeightMg: 0,
      karat: 21,
    ),
    'G-1301': GoldSaleProduct(
      code: 'G-1301',
      name: 'سوار ذهب',
      status: GoldItemStatus.available,
      grossWeightMg: 5000,
      stonesWeightMg: 200,
      karat: 21,
      defaultLaborValue: 10000,
      defaultLaborType: LaborPricingType.perGram,
    ),
  };

  void markSold(String code) {
    _soldCodes.add(code.trim().toUpperCase());
  }

  bool isSold(String code) => _soldCodes.contains(code.trim().toUpperCase());

  List<GoldSaleProduct> get demoItems => List.unmodifiable(
    _records.values.map(
      (product) => isSold(product.code)
          ? product.copyWith(status: GoldItemStatus.sold)
          : product,
    ),
  );

  GoldSaleProduct? findByCode(String code) {
    final normalized = code.trim().toUpperCase();
    final product = _records[normalized];
    if (product == null) return null;
    return isSold(normalized)
        ? product.copyWith(status: GoldItemStatus.sold)
        : product;
  }
}
