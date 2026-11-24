import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';

class GoldSaleRecord {
  GoldSaleRecord._(this.data);

  final Map<String, dynamic> data;

  String get id => data['id'] as String;

  factory GoldSaleRecord.fromCart({
    required GoldSaleCart cart,
    required List<GoldSalePayment> payments,
    required DateTime recordedAt,
  }) {
    final lines = cart.lineResults;
    final trade = cart.tradeIn;

    return GoldSaleRecord._({
      'id': recordedAt.microsecondsSinceEpoch.toString(),
      'recordedAt': recordedAt.toIso8601String(),
      'items': [
        for (var i = 0; i < cart.items.length; i++)
          {
            'code': cart.items[i].code,
            'grossWeightMg': cart.items[i].input.grossWeightMg,
            'stonesWeightMg': cart.items[i].input.stonesWeightMg,
            'karat': cart.items[i].input.karat,
            'goldPricePerGramPiasters':
                cart.items[i].input.goldPricePerGramPiasters,
            'laborValue': cart.items[i].input.laborValue,
            'laborPricingType': cart.items[i].input.laborPricingType.name,
            'netWeightMg': lines[i].netWeightMg,
            'goldValuePiasters': lines[i].goldValuePiasters,
            'discountPiasters': lines[i].discountPiasters,
            'laborAfterDiscountPiasters': lines[i].laborAfterDiscountPiasters,
            'taxPiasters': lines[i].taxPiasters,
            'totalPiasters': lines[i].totalPiasters,
          },
      ],
      'discountPercent': cart.discountPercent,
      'supervisorApprovalNumber': cart.supervisorApprovalNumber,
      'tradeIn': trade == null
          ? null
          : {
              'weightMg': trade.weightMg,
              'karat': trade.karat,
              'buyPricePerGramPiasters': trade.buyPricePerGramPiasters,
              'deductionBasisPoints': trade.deductionBasisPoints,
              'valuePiasters': cart.tradeInValuePiasters,
            },
      'totalPiasters': cart.totalPiasters,
      'amountDuePiasters': cart.amountDuePiasters,
      'payments': [
        for (final p in payments)
          {'method': p.method.name, 'amountPiasters': p.amountPiasters},
      ],
    });
  }
}