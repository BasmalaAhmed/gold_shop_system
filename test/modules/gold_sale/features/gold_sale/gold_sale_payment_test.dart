import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';

void main() {
  group('GoldSalePaymentValidator', () {
    const validator = GoldSalePaymentValidator();
    const amountDue = 1815710;

    test('accepts cash and card payments matching the amount exactly', () {
      const payments = [
        GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: 1000000,
        ),
        GoldSalePayment(
          method: GoldSalePaymentMethod.card,
          amountPiasters: 815710,
        ),
      ];

      expect(
        () => validator.validate(
          amountDuePiasters: amountDue,
          payments: payments,
        ),
        returnsNormally,
      );
    });

    test('rejects payment that is short by one piastre', () {
      const payments = [
        GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: 1000000,
        ),
        GoldSalePayment(
          method: GoldSalePaymentMethod.card,
          amountPiasters: 815709,
        ),
      ];

      expect(
        () => validator.validate(
          amountDuePiasters: amountDue,
          payments: payments,
        ),
        throwsArgumentError,
      );
    });

    test('rejects payment that exceeds the amount due by one piastre', () {
      const payments = [
        GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: 1000000,
        ),
        GoldSalePayment(
          method: GoldSalePaymentMethod.card,
          amountPiasters: 815711,
        ),
      ];

      expect(
        () => validator.validate(
          amountDuePiasters: amountDue,
          payments: payments,
        ),
        throwsArgumentError,
      );
    });
  });
}