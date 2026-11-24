import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/domain/entities/gold_price.dart';

abstract class GoldPriceRepo {
  Future<GoldPrice> getGoldPrice();

  Stream<GoldPrice> watchGoldPrice();
}
