import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_price_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_price_repo.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/service_locator.dart'
    as monitoring_locator;
import 'package:gold_shop_app/modules/shop_monitoring/core/session/account_session.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/datasources/mock_monitoring_api_registry.dart';

class MonitoringGoldSalePriceRepo implements GoldSalePriceRepo {
  MonitoringGoldSalePriceRepo({this._fallback = const GoldSaleDemoPriceRepo()});

  final GoldSalePriceRepo _fallback;

  static const int _saleMarkupPiasters = 20000;
  static const int _buyMarkupPiasters = 5000;

  Future<int?> _price21Piasters() async {
    try {
      final api = monitoring_locator
          .getIt<MockMonitoringApiRegistry>()
          .forAccount(AccountSession.defaultAccountId);
      final price = await api.fetchGoldPrice();
      return price.value * 100;
    } catch (_) {
      return null;
    }
  }

  int _forKarat(int price21Piasters, int karat) =>
      (price21Piasters * karat + 10) ~/ 21;

  @override
  Future<int> getSalePricePerGramPiasters(int karat) async {
    final base = await _price21Piasters();
    if (base == null) return _fallback.getSalePricePerGramPiasters(karat);
    _ensureSupported(karat);
    return _forKarat(base + _saleMarkupPiasters, karat);
  }

  @override
  Future<int> getBuyPricePerGramPiasters(int karat) async {
    final base = await _price21Piasters();
    if (base == null) return _fallback.getBuyPricePerGramPiasters(karat);
    _ensureSupported(karat);
    return _forKarat(base + _buyMarkupPiasters, karat);
  }

  void _ensureSupported(int karat) {
    if (!GoldSaleDemoPriceRepo.supportedKarats.contains(karat)) {
      throw StateError('No price configured for karat $karat.');
    }
  }
}
