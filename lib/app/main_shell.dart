import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/app/unified_dependencies.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/views/home_view.dart'
    as auth_view;
import 'package:gold_shop_app/modules/debts_payment/app/main_navigation_shell.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/views/home_view.dart'
    as gold_view;
import 'package:gold_shop_app/modules/shop_approval/app/auto_refresh.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/views/approval_requests_view.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/lifecycle/app_lifecycle_observer.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/service_locator.dart'
    as monitoring_locator;
import 'package:gold_shop_app/modules/shop_monitoring/core/session/account_manager.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/session/account_session.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/presentation/manager/cubits/branch_monitoring_cubit/branch_monitoring_cubit.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/presentation/views/account_scope.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/presentation/views/branch_monitoring_view.dart';

class UnifiedMainShell extends StatefulWidget {
  final UnifiedDependencies dependencies;
  final bool Function(Uri uri) onDeepLink;

  const UnifiedMainShell({
    super.key,
    required this.dependencies,
    required this.onDeepLink,
  });

  @override
  State<UnifiedMainShell> createState() => _UnifiedMainShellState();
}

class _UnifiedMainShellState extends State<UnifiedMainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          gold_view.HomeView(
            priceRepository: widget.dependencies.goldPriceRepo,
          ),

          AccountScope(
            session: monitoring_locator.getIt<AccountSession>(),
            createCubit: monitoring_locator.createBranchMonitoringCubit,
            builder: (context, accountId) {
              return AppLifecycleObserver(
                onResumed: () {
                  context.read<BranchMonitoringCubit>().refresh();
                },
                child: BranchMonitoringView(
                  onSwitchAccount: () {
                    monitoring_locator.getIt<AccountManager>().switchTo(
                      accountId == AccountSession.defaultAccountId
                          ? 'shop_2'
                          : AccountSession.defaultAccountId,
                    );
                  },
                ),
              );
            },
          ),

          MainNavigationShell(
            api: widget.dependencies.debtsApi,
            repository: widget.dependencies.debtsRepository,
            syncWorker: widget.dependencies.debtsSyncWorker,
            network: widget.dependencies.debtsNetwork,
            connectivityObserver: widget.dependencies.debtsConnectivityObserver,
          ),

          const AutoRefresh(
            child: ApprovalRequestsView(),
          ),

          auth_view.HomeView(
            sessionManager: widget.dependencies.authDependencies.sessionManager,
            onDeepLink: widget.onDeepLink,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: UnifiedTheme.emerald.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded, color: UnifiedTheme.teal),
              label: 'بيع الذهب',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded, color: UnifiedTheme.teal),
              label: 'مراقبة الفرع',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded, color: UnifiedTheme.teal),
              label: 'تحصيل الديون',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded, color: UnifiedTheme.teal),
              label: 'الموافقات',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts_rounded, color: UnifiedTheme.teal),
              label: 'الحساب',
            ),
          ],
        ),
      ),
    );
  }
}
