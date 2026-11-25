import 'dart:async';

import 'package:gold_shop_app/modules/debts_payment/data/local/models/queue_summary.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/device_connectivity_observer.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/sync_on_reconnect.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/sync_worker.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/customer_debt_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/pending_operations_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
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
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final SyncOnReconnect _syncOnReconnect;
  late final StreamSubscription<void> _syncSubscription;
  final ValueNotifier<QueueSummary> _summary = ValueNotifier(
    QueueSummary.empty,
  );

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _syncOnReconnect = SyncOnReconnect(
      network: widget.network,
      syncWorker: widget.syncWorker,
    );

    _syncSubscription = _syncOnReconnect.syncCompleted.listen((_) {
      _refreshSummary();
    });

    _refreshSummary();
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    _summary.dispose();
    unawaited(_syncOnReconnect.dispose());
    super.dispose();
  }

  Future<void> _refreshSummary() async {
    try {
      final summary = await widget.repository.getQueueSummary();
      if (!mounted) return;
      _summary.value = summary;
    } catch (_) {
      return;
    }
  }

  void _onPaymentSaved() {
    _refreshSummary();
    if (widget.network.isOnline) {
      unawaited(_syncOnReconnect.syncNow());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ValueListenableBuilder<QueueSummary>(
              valueListenable: _summary,
              builder: (context, summary, child) {
                return AppBottomNav(
                  selectedIndex: _selectedIndex,
                  summary: summary,
                  onSelected: (index) {
                    setState(() => _selectedIndex = index);
                    _refreshSummary();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _selectedIndex == 0
                  ? CustomerDebtView(
                      customerId: 'customer-001',
                      repository: widget.repository,
                      api: widget.api,
                      network: widget.network,
                      syncCompleted: _syncOnReconnect.syncCompleted,
                      onChanged: _onPaymentSaved,
                    )
                  : PendingOperationsView(
                      repository: widget.repository,
                      api: widget.api,
                      network: widget.network,
                      syncOnReconnect: _syncOnReconnect,
                      onChanged: _onPaymentSaved,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
