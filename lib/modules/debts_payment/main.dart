import 'package:gold_shop_app/modules/debts_payment/app/main_navigation_shell.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/device_connectivity_observer.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/sync_worker.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase.instance;
  final network = MockNetwork();
  final connectivityObserver = DeviceConnectivityObserver(network: network);

  await connectivityObserver.start();

  final api = MockDebtApi(network: network);
  final repository = PaymentRepo(database: database);
  final syncWorker = SyncWorker(database: database, api: api);
  await syncWorker.recoverInterrupted();

  runApp(
    DebtPaymentApp(
      api: api,
      repository: repository,
      syncWorker: syncWorker,
      network: network,
      connectivityObserver: connectivityObserver,
    ),
  );
}

class DebtPaymentApp extends StatelessWidget {
  const DebtPaymentApp({
    super.key,
    required this.api,
    required this.repository,
    required this.syncWorker,
    required this.network,
    required this.connectivityObserver,
  });

  final MockDebtApi api;
  final PaymentRepo repository;
  final SyncWorker syncWorker;
  final MockNetwork network;
  final DeviceConnectivityObserver connectivityObserver;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تحصيل الأقساط',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MainNavigationShell(
        api: api,
        repository: repository,
        syncWorker: syncWorker,
        network: network,
        connectivityObserver: connectivityObserver,
      ),
    );
  }
}
