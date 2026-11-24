import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';

void main() {
  group('GoldSaleCart', () {
    GoldSaleCartItem item(
      String code, {
      GoldItemStatus status = GoldItemStatus.available,
    }) {
      return GoldSaleCartItem(
        code: code,
        status: status,
        input: const GoldSaleInput(
          grossWeightMg: 4500,
          stonesWeightMg: 300,
          karat: 21,
          goldPricePerGramPiasters: 420000,
          laborValue: 12000,
          laborPricingType: LaborPricingType.perGram,
        ),
      );
    }

    test('adds two different items and sums their rounded totals', () {
      final basket = GoldSaleCart()
        ..add(item('A-1'))
        ..add(item('B-2'))
        ..setDiscount(discountPercent: 10);

      expect(basket.items, hasLength(2));
      expect(basket.totalPiasters, 3631420);
    });

    test('rejects the same code even if letter case differs', () {
      final basket = GoldSaleCart()..add(item('ab-1'));

      expect(() => basket.add(item('AB-1')), throwsStateError);
    });

    test('rejects a third item', () {
      final basket = GoldSaleCart()
        ..add(item('A-1'))
        ..add(item('B-2'));

      expect(() => basket.add(item('C-3')), throwsStateError);
    });

    test('rejects items unavailable for a normal sale', () {
      final basket = GoldSaleCart();

      for (final status in [
        GoldItemStatus.reserved,
        GoldItemStatus.sold,
        GoldItemStatus.inWorkshop,
        GoldItemStatus.inTransit,
      ]) {
        expect(
          () => basket.add(item('ITEM-1', status: status)),
          throwsStateError,
        );
      }
    });

    test('applies the invoice discount to each item line', () {
      final basket = GoldSaleCart()
        ..add(item('A-1'))
        ..add(item('B-2'))
        ..setDiscount(discountPercent: 5);

      expect(basket.lineResults.map((line) => line.discountPiasters).toList(), [
        2520,
        2520,
      ]);
    });

    test(
      'rejects discount above 10% without approval and keeps old discount',
      () {
        final basket = GoldSaleCart()
          ..add(item('A-1'))
          ..setDiscount(discountPercent: 5);

        expect(
          () => basket.setDiscount(discountPercent: 11),
          throwsArgumentError,
        );

        expect(basket.lineResults.single.discountPiasters, 2520);
      },
    );

    test('accepts discount above 10% with approval number', () {
      final basket = GoldSaleCart()
        ..add(item('A-1'))
        ..setDiscount(discountPercent: 11, supervisorApprovalNumber: 'APR-123');

      expect(basket.lineResults.single.discountPiasters, 5544);
    });
  });
}
