import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';

class GoldSaleDraft {
  GoldSaleDraft({
    required this.items,
    required this.discountPercent,
    required this.supervisorApprovalNumber,
    required this.cashAmountText,
    required this.otherAmountText,
    required this.otherMethod,
    this.tradeIn,
    this.savedAt,
    this.pendingApprovalRequestId,
  });

  final List<GoldSaleCartItem> items;
  final int discountPercent;
  final String? supervisorApprovalNumber;
  final String cashAmountText;
  final String otherAmountText;
  final GoldSalePaymentMethod otherMethod;
  final TradeInInput? tradeIn;
  final DateTime? savedAt;
  final int? pendingApprovalRequestId;

  Map<String, dynamic> toJson() => {
    'items': items.map((item) {
      final input = item.input;

      return {
        'code': item.code,
        'name': item.name,
        'status': item.status.name,
        'input': {
          'grossWeightMg': input.grossWeightMg,
          'stonesWeightMg': input.stonesWeightMg,
          'karat': input.karat,
          'goldPricePerGramPiasters': input.goldPricePerGramPiasters,
          'laborValue': input.laborValue,
          'laborPricingType': input.laborPricingType.name,
        },
      };
    }).toList(),
    'discountPercent': discountPercent,
    'supervisorApprovalNumber': supervisorApprovalNumber,
    'pendingApprovalRequestId': pendingApprovalRequestId,
    'cashAmountText': cashAmountText,
    'otherAmountText': otherAmountText,
    'otherMethod': otherMethod.name,
    'savedAt': savedAt?.toIso8601String(),
    'tradeIn': tradeIn == null
        ? null
        : {
            'weightMg': tradeIn!.weightMg,
            'karat': tradeIn!.karat,
            'buyPricePerGramPiasters': tradeIn!.buyPricePerGramPiasters,
            'deductionBasisPoints': tradeIn!.deductionBasisPoints,
          },
  };

  factory GoldSaleDraft.fromJson(Map<String, dynamic> json) {
    final itemJsonList = json['items'] as List<dynamic>;

    final items = itemJsonList.map((itemEntry) {
      final itemJson = itemEntry as Map<String, dynamic>;
      final inputJson = itemJson['input'] as Map<String, dynamic>;

      return GoldSaleCartItem(
        code: itemJson['code'] as String,
        name: itemJson['name'] as String? ?? 'قطعة ذهب',
        status: GoldItemStatus.values.byName(itemJson['status'] as String),
        input: GoldSaleInput(
          grossWeightMg: inputJson['grossWeightMg'] as int,
          stonesWeightMg: inputJson['stonesWeightMg'] as int,
          karat: inputJson['karat'] as int,
          goldPricePerGramPiasters:
              inputJson['goldPricePerGramPiasters'] as int,
          laborValue: inputJson['laborValue'] as int,
          laborPricingType: LaborPricingType.values.byName(
            inputJson['laborPricingType'] as String,
          ),
        ),
      );
    }).toList();

    final tradeInJson = json['tradeIn'] as Map<String, dynamic>?;

    return GoldSaleDraft(
      tradeIn: tradeInJson == null || tradeInJson['karat'] == null
          ? null
          : TradeInInput(
              weightMg: tradeInJson['weightMg'] as int,
              karat: tradeInJson['karat'] as int,
              buyPricePerGramPiasters:
                  tradeInJson['buyPricePerGramPiasters'] as int,
              deductionBasisPoints: tradeInJson['deductionBasisPoints'] as int,
            ),
      items: items,
      discountPercent: json['discountPercent'] as int,
      supervisorApprovalNumber: json['supervisorApprovalNumber'] as String?,
      pendingApprovalRequestId: json['pendingApprovalRequestId'] as int?,
      cashAmountText: json['cashAmountText'] as String,
      otherAmountText: json['otherAmountText'] as String,
      otherMethod: GoldSalePaymentMethod.values.byName(
        json['otherMethod'] as String,
      ),
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'] as String)
          : null,
    );
  }
}
