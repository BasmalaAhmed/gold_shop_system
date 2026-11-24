import 'dart:async';

import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/data/services/sync_on_reconnect.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/conflict_review_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/app_header.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/debt_error_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/operations_list.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/pending_status_badge.dart';
import 'package:flutter/material.dart';

class PendingOperationsView extends StatefulWidget {
  const PendingOperationsView({
    super.key,
    required this.repository,
    required this.api,
    required this.network,
    required this.syncOnReconnect,
    this.onChanged,
  });

  final PaymentRepo repository;
  final MockDebtApi api;
  final MockNetwork network;
  final SyncOnReconnect syncOnReconnect;
  final VoidCallback? onChanged;

  @override
  State<PendingOperationsView> createState() =>
      _PendingOperationsViewState();
}

class _PendingOperationsViewState extends State<PendingOperationsView> {
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _autoSyncing = false;
  String? _error;
  List<SyncOperation> _operations = [];
  String _deviceLabel = '';

  late final StreamSubscription<void> _syncSubscription;
  late final StreamSubscription<bool> _networkSubscription;

  @override
  void initState() {
    super.initState();

    _syncSubscription = widget.syncOnReconnect.syncCompleted.listen((_) {
      _autoSyncing = false;
      _load(showLoading: false);
    });

    _networkSubscription = widget.network.changes.listen((online) {
      if (!mounted) return;
      setState(() => _autoSyncing = online);
    });

    _load();
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    _networkSubscription.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final operations = await widget.repository.getSyncOperations();
      final deviceId = await widget.repository.getOrCreateDeviceId();

      if (!mounted) return;
      setState(() {
        _operations = operations;
        _deviceLabel = deviceId.length < 2
            ? deviceId
            : deviceId.substring(0, 2).toUpperCase();
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      await widget.syncOnReconnect.syncNow();
      await _load(showLoading: false);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _openConflict(SyncOperation operation) async {
    final resolved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConflictReviewView(
          operation: operation,
          repository: widget.repository,
          api: widget.api,
          network: widget.network,
        ),
      ),
    );

    if (!mounted) return;
    await _load(showLoading: false);
    if (resolved == true) widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'طابور الإرسال',
            subtitle: _deviceLabel.isEmpty ? null : 'جهاز $_deviceLabel',
            trailing: PendingStatusBadge(
              operations: _operations,
              isOnline: widget.network.isOnline,
              isSyncing: _isSyncing,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _operations.isEmpty
                ? DebtErrorView(errorMessage: _error!, onRetry: _load)
                : OperationsList(
                    operations: _operations,
                    network: widget.network,
                    isSyncing: _isSyncing,
                    autoSyncing: _autoSyncing,
                    onRefresh: _syncNow,
                    onOpenConflict: _openConflict,
                  ),
          ),
        ],
      ),
    );
  }
}
