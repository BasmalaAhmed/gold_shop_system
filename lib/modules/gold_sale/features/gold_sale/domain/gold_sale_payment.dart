import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';

class GoldSalePayment {
  const GoldSalePayment({required this.method, required this.amountPiasters});

  final GoldSalePaymentMethod method;
  final int amountPiasters;
}

class GoldSalePaymentValidator {
  const GoldSalePaymentValidator();

  void validate({
    required int amountDuePiasters,
    required List<GoldSalePayment> payments,
  }) {
    if (amountDuePiasters <= 0) {
      throw ArgumentError('Amount due must be greater than zero.');
    }

    if (payments.isEmpty) {
      throw ArgumentError('At least one payment is required.');
    }

    if (payments.any((payment) => payment.amountPiasters <= 0)) {
      throw ArgumentError('Payment amounts must be greater than zero.');
    }

    final paidPiasters = payments.fold<int>(
      0,
      (sum, payment) => sum + payment.amountPiasters,
    );

    if (paidPiasters != amountDuePiasters) {
      throw ArgumentError('Payment total must exactly match the amount due.');
    }
  }

  String? errorMessage({
    required int amountDuePiasters,
    required List<GoldSalePayment> payments,
  }) {
    if (amountDuePiasters <= 0) {
      return 'المبلغ المطلوب يجب أن يكون أكبر من صفر. راجع الخصم أو البدل.';
    }
    if (payments.isEmpty) return 'أدخل مبلغ الدفع.';
    if (payments.any((p) => p.amountPiasters <= 0)) {
      return 'مبالغ الدفع يجب أن تكون أكبر من صفر.';
    }

    final paid = payments.fold<int>(0, (sum, p) => sum + p.amountPiasters);

    if (paid > amountDuePiasters) return 'المبلغ المدفوع أكبر من المطلوب.';
    if (paid != amountDuePiasters) {
      return 'مجموع المدفوعات يجب أن يساوي المطلوب بالضبط.';
    }
    return null;
  }
}
