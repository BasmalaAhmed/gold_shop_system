import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/gold_price_model.dart';

abstract class GoldPriceApi {
  Future<GoldPriceModel> fetchGoldPrice();

  Stream<GoldPriceModel> goldPriceUpdates();
}
