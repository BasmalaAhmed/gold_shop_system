import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_price_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';

GoldSaleCartItem _item(String code) => GoldSaleCartItem(
  code: code,
  status: GoldItemStatus.available,
  input: const GoldSaleInput(
    grossWeightMg: 4500,
    stonesWeightMg: 300,
    karat: 21,
    goldPricePerGramPiasters: 420000,
    laborValue: 12000,
    laborPricingType: LaborPricingType.perGram,
  ),
);

void main() {
  const calc = TradeInCalc();

  group('TradeInCalc', () {
    test('rounds weight to mg first, then value at buy price', () {
      final r = calc.calculate(
        const TradeInInput(
          karat: 21,
          weightMg: 2000,
          buyPricePerGramPiasters: 400000,
          deductionBasisPoints: 250,
        ),
      );
      expect(r.weightAfterDeductionMg, 1950);
      expect(r.valuePiasters, 780000);
    });

    test('half milligram rounds up', () {
      final r = calc.calculate(
        const TradeInInput(
          karat: 21,
          weightMg: 1001,
          buyPricePerGramPiasters: 100000,
          deductionBasisPoints: 5000,
        ),
      );
      expect(r.weightAfterDeductionMg, 501);
      expect(r.valuePiasters, 50100);
    });

    test('half piaster rounds up', () {
      final r = calc.calculate(
        const TradeInInput(karat: 21, weightMg: 3, buyPricePerGramPiasters: 1500),
      );
      expect(r.valuePiasters, 5);
    });

    test('rejects zero weight, zero price and 100% deduction', () {
      for (final input in const [
        TradeInInput(karat: 21, weightMg: 0, buyPricePerGramPiasters: 1),
        TradeInInput(karat: 21, weightMg: 1, buyPricePerGramPiasters: 0),
        TradeInInput(
          karat: 21,
          weightMg: 1,
          buyPricePerGramPiasters: 1,
          deductionBasisPoints: 10000,
        ),
      ]) {
        expect(() => calc.calculate(input), throwsArgumentError);
      }
    });
  });

  group('Cart with trade-in', () {
    test('amount due = total - trade-in, and payments match it exactly', () {
      final cart = GoldSaleCart()
        ..add(_item('A-1'))
        ..setDiscount(discountPercent: 10)
        ..setTradeIn(
          const TradeInInput(
            karat: 21,
            weightMg: 2000,
            buyPricePerGramPiasters: 400000,
            deductionBasisPoints: 250,
          ),
        );

      expect(cart.totalPiasters, 1815710);
      expect(cart.amountDuePiasters, 1035710);

      const validator = GoldSalePaymentValidator();
      List<GoldSalePayment> pay(int other) => [
        const GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: 1000000,
        ),
        GoldSalePayment(method: GoldSalePaymentMethod.card, amountPiasters: other),
      ];

      expect(
        () => validator.validate(
          amountDuePiasters: cart.amountDuePiasters,
          payments: pay(35710),
        ),
        returnsNormally,
      );
      expect(
        () => validator.validate(
          amountDuePiasters: cart.amountDuePiasters,
          payments: pay(35709),
        ),
        throwsArgumentError,
      );
    });

    test('rejects trade-in worth more than the invoice', () {
      final cart = GoldSaleCart()
        ..add(_item('A-1'))
        ..setDiscount(discountPercent: 10);

      expect(
        () => cart.setTradeIn(
          const TradeInInput(
            karat: 21,
            weightMg: 5000,
            buyPricePerGramPiasters: 420000,
          ),
        ),
        throwsArgumentError,
      );
      expect(cart.tradeIn, isNull);
    });
  });

  test('demo buy price per karat is separate from (and below) the sale price',
      () async {
    const repo = GoldSaleDemoPriceRepo();
    for (final karat in GoldSaleDemoPriceRepo.supportedKarats) {
      final buy = await repo.getBuyPricePerGramPiasters(karat);
      final sale = await repo.getSalePricePerGramPiasters(karat);
      expect(buy, lessThan(sale));
    }
    expect(() => repo.getBuyPricePerGramPiasters(14), throwsStateError);
  });

      test('rejects karat outside 18, 21, 24', () {
      expect(
        () => calc.calculate(
          const TradeInInput(karat: 22, weightMg: 1000, buyPricePerGramPiasters: 1),
        ),
        throwsArgumentError,
      );
    });
}