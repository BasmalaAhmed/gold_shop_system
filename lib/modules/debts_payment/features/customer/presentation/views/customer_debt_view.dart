import 'dart:async';

import 'package:gold_shop_app/modules/debts_payment/core/customers/customer_info.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/conflict_review_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/payment_entry_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/customer_debt_content.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/customer_header.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/debt_bottom_bar.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/debt_error_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/debt_status_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomerDebtView extends StatefulWidget {
  const CustomerDebtView({
    super.key,
    required this.customerId,
    required this.repository,
    required this.api,
    required this.network,
    required this.syncCompleted,
    this.onChanged,
  });

  final String customerId;
  final PaymentRepo repository;
  final MockDebtApi api;
  final MockNetwork network;
  final Stream<void> syncCompleted;
  final VoidCallback? onChanged;

  @override
  State<CustomerDebtView> createState() => _CustomerDebtViewState();
}

class _CustomerDebtViewState extends State<CustomerDebtView> {
  List<DebtBalance> _debts = [];
  List<SyncOperation> _operations = [];
  bool _isLoading = true;
  String? _error;

  late final StreamSubscription<void> _syncSubscription;
  late final StreamSubscription<bool> _networkSubscription;

  @override
  void initState() {
    super.initState();

    _syncSubscription = widget.syncCompleted.listen((_) {
      _loadDebts(showLoading: false);
    });

    _networkSubscription = widget.network.changes.listen((isOnline) {
      if (!mounted) return;
      setState(() {});
      if (isOnline) _loadDebts(showLoading: false);
    });

    _loadDebts();
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    _networkSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadDebts({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      var debts = await widget.repository.getDebtBalances(widget.customerId);

      if (debts.isEmpty) {
        final serverDebts = await widget.api.fetchDebts(widget.customerId);
        await widget.repository.cacheDebts(widget.customerId, serverDebts);
        debts = await widget.repository.getDebtBalances(widget.customerId);
      } else if (widget.network.isOnline) {
        try {
          final serverDebts = await widget.api.fetchDebts(widget.customerId);
          final refreshed = await widget.repository.refreshDebtsIfIdle(
            widget.customerId,
            serverDebts,
          );
          if (refreshed) {
            debts = await widget.repository.getDebtBalances(widget.customerId);
          }
        } catch (_) {}
      }

      final operations = await widget.repository.getSyncOperations();

      if (!mounted) return;
      setState(() {
        _debts = debts;
        _operations = operations
            .where((o) => o.customerId == widget.customerId)
            .toList();
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (showLoading || _debts.isEmpty) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  SyncOperation? get _conflictOp {
    for (final op in _operations) {
      if (op.uiState == OpUiState.conflict) return op;
    }
    return null;
  }

  Future<void> _openPaymentEntry() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaymentEntryView(
          customerId: widget.customerId,
          repository: widget.repository,
          debts: _debts,
          network: widget.network,
          onSaved: widget.onChanged,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadDebts(showLoading: false);
    }
  }

  Future<void> _openConflictReview(SyncOperation operation) async {
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

    if (resolved == true && mounted) {
      await _loadDebts(showLoading: false);
      widget.onChanged?.call();
    }
  }

  Future<void> _debugOtherDevicePayment() async {
    try {
      await widget.api.simulateOtherDevicePayment(
        customerId: widget.customerId,
        amount: 50000,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('محاكاة: جهاز B2 حصّل 500.00 ج.م على الخادم'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذّرت المحاكاة: $error')));
    }
  }

  void _showDebugSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.devices_other),
              title: const Text('جهاز B2 يحصّل 500.00 على الخادم'),
              onTap: () {
                Navigator.pop(ctx);
                _debugOtherDevicePayment();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = customerInfoFor(widget.customerId);
    final conflictOp = _conflictOp;
    final showBottomButton = !_isLoading && _error == null && _debts.isNotEmpty;

    return Scaffold(
      body: Column(
        children: [
          CustomerHeader(
            name: info.name,
            phone: info.phone,
            chip: DebtStatusBadge(
              operations: _operations,
              isOnline: widget.network.isOnline,
            ),
            onDebugTap: kDebugMode ? _showDebugSheet : null,
          ),
          Expanded(child: _buildBody(info, conflictOp)),
        ],
      ),
      bottomNavigationBar: showBottomButton
          ? DebtBottomBar(
              hasConflict: conflictOp != null,
              onPressed: conflictOp != null
                  ? () => _openConflictReview(conflictOp)
                  : _openPaymentEntry,
            )
          : null,
    );
  }

  Widget _buildBody(CustomerInfo info, SyncOperation? conflictOp) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return DebtErrorView(errorMessage: _error!, onRetry: _loadDebts);
    }

    if (_debts.isEmpty) {
      return const Center(child: Text('لا يوجد مديونيات مسجلة للعميل.'));
    }

    return CustomerDebtContent(
      info: info,
      debts: _debts,
      conflictOp: conflictOp,
      onRefresh: () => _loadDebts(showLoading: false),
      onDebugLongPress: _debugOtherDevicePayment,
    );
  }
}
