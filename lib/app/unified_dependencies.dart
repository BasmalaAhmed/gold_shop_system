import 'package:app_links/app_links.dart';
import 'package:gold_shop_app/modules/auth_notification/core/app_dependencies.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/device_connectivity_observer.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/sync_worker.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_price_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_price_repo.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_service.dart'
    as approval_conn;
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/mock_api_scenario.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/mock_approval_api.dart'
    as shop_approval_mock;
import 'package:gold_shop_app/modules/shop_approval/features/approvals/data/mock_approval_data.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/service_locator.dart'
    as monitoring_locator;

class UnifiedDependencies {
  final AppDependencies authDependencies;
  final AppLinks appLinks;
  final AppDatabase debtsDatabase;
  final MockNetwork debtsNetwork;
  final DeviceConnectivityObserver debtsConnectivityObserver;
  final MockDebtApi debtsApi;
  final PaymentRepo debtsRepository;
  final SyncWorker debtsSyncWorker;
  final approval_conn.ConnectivityService approvalConnectivity;
  final shop_approval_mock.MockApprovalApi approvalApi;
  final GoldSalePriceRepo goldPriceRepo;

  UnifiedDependencies({
    required this.authDependencies,
    required this.appLinks,
    required this.debtsDatabase,
    required this.debtsNetwork,
    required this.debtsConnectivityObserver,
    required this.debtsApi,
    required this.debtsRepository,
    required this.debtsSyncWorker,
    required this.approvalConnectivity,
    required this.approvalApi,
    required this.goldPriceRepo,
  });

  static Future<UnifiedDependencies> create() async {
    final appLinks = AppLinks();
    final authDeps = await AppDependencies.create();
    final debtsDb = AppDatabase.instance;
    final debtsNet = MockNetwork();
    final debtsConnObserver = DeviceConnectivityObserver(network: debtsNet);
    await debtsConnObserver.start();

    final debtsApi = MockDebtApi(network: debtsNet);
    final debtsRepo = PaymentRepo(database: debtsDb);
    final debtsSync = SyncWorker(database: debtsDb, api: debtsApi);
    await debtsSync.recoverInterrupted();

    final approvalConn = approval_conn.ConnectivityPlusService();
    await approvalConn.init();
    final approvalMockApi = shop_approval_mock.MockApprovalApi(
      initialRequests: createMockApprovalRequests(),
      scenario: MockApiScenario.normal,
    );

    await monitoring_locator.setupDependencies();

    const goldPriceRepo = GoldSaleDemoPriceRepo();

    return UnifiedDependencies(
      authDependencies: authDeps,
      appLinks: appLinks,
      debtsDatabase: debtsDb,
      debtsNetwork: debtsNet,
      debtsConnectivityObserver: debtsConnObserver,
      debtsApi: debtsApi,
      debtsRepository: debtsRepo,
      debtsSyncWorker: debtsSync,
      approvalConnectivity: approvalConn,
      approvalApi: approvalMockApi,
      goldPriceRepo: goldPriceRepo,
    );
  }

  Future<void> dispose() async {
    await debtsConnectivityObserver.dispose();
    await debtsDatabase.close();
    await monitoring_locator.disposeDependencies();
  }
}
