import 'package:gold_shop_app/modules/shop_monitoring/core/service_locator.dart'
    as monitoring_locator;
import 'package:gold_shop_app/modules/shop_monitoring/core/session/account_session.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/datasources/mock_monitoring_api_registry.dart';

class MonitoringSaleRecorder {
  MonitoringSaleRecorder({this.branchId = 'a3'});

  final String branchId;

  void record({
    required List<String> itemCodes,
    required int totalPiasters,
    required int cashPiasters,
  }) {
    final api = monitoring_locator
        .getIt<MockMonitoringApiRegistry>()
        .forAccount(AccountSession.defaultAccountId);

    api.recordSale(
      branchId: branchId,
      salesAmount: _toEgp(totalPiasters),
      cashAmount: _toEgp(cashPiasters),
      itemsLabel: itemCodes.join('، '),
    );
  }

  int _toEgp(int piasters) => (piasters / 100).round();
}
