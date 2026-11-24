import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_price_repo.dart';

int _calculateKaratPrice(int price21Piasters, int karat) {
  return (price21Piasters * karat + 10) ~/ 21;
}

class GoldSaleDemoPriceRepo implements GoldSalePriceRepo {
  const GoldSaleDemoPriceRepo();

  static const int _salePrice21Piasters = 420000;
  static const int _buyPrice21Piasters = 405000;

  static const List<int> supportedKarats = [24, 21, 18];

  @override
  Future<int> getSalePricePerGramPiasters(int karat) async {
    if (!supportedKarats.contains(karat)) {
      throw StateError('No sale price configured for karat $karat.');
    }
    return _calculateKaratPrice(_salePrice21Piasters, karat);
  }

  @override
  Future<int> getBuyPricePerGramPiasters(int karat) async {
    if (!supportedKarats.contains(karat)) {
      throw StateError('No buy price configured for karat $karat.');
    }

    return _calculateKaratPrice(_buyPrice21Piasters, karat);
  }
}
