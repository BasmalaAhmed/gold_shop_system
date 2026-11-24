import 'package:gold_shop_app/modules/debts_payment/core/customers/customer_info.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/time_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/payment_saved_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/amount_card.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/app_header.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/conflict_bottom_actions.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/reason_card.dart';
import 'package:flutter/material.dart';

class ConflictReviewView extends StatefulWidget {
  const ConflictReviewView({
    super.key,
    required this.operation,
    required this.repository,
    required this.api,
    required this.network,
  });

  final SyncOperation operation;
  final PaymentRepo repository;
  final MockDebtApi api;
  final MockNetwork network;

  @override
  State<ConflictReviewView> createState() => _ConflictReviewViewState();
}

class _ConflictReviewViewState extends State<ConflictReviewView> {
  bool _busy = false;
  String? _error;

  SyncOperation get _op => widget.operation;

  String _reason(String customerName) {
    final device = _op.conflictOtherDevice;
    final amount = _op.conflictOtherAmount;
    final at = _op.conflictOtherAt;

    if (device != null && amount != null) {
      final when = at == null ? '' : ' الساعة ${formatClock(at)}';
      return 'حُصِّل من جهاز آخر ($device) مبلغ ${formatEgp(amount)} '
          'من $customerName$when أثناء انقطاع اتصالك.';
    }

    if (_op.conflictServerBalance == null) {
      return 'لم يقبل الخادم هذه العملية. راجع العميل قبل أي إجراء.';
    }

    return 'تغيّر رصيد العميل على الخادم أثناء انقطاع اتصالك.';
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('رجوع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: danger ? AppColors.conflictText : AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
    } on MockNetworkUnavailable {
      _setError(
        'لا يوجد اتصال. حل التعارض يحتاج اتصالاً لتحديث رصيد الخادم. '
        'لم يتغيّر أي شيء.',
      );
    } on ConflictResolutionBlocked catch (error) {
      _setError(error.message);
    } catch (error) {
      _setError('تعذّر تنفيذ الإجراء: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replace() async {
    final serverBalance = _op.conflictServerBalance;
    final exceeds = serverBalance != null && _op.amount > serverBalance;
    final target = exceeds ? serverBalance : _op.amount;

    final ok = await _confirm(
      title: exceeds ? 'تعديل المبلغ' : 'إعادة التسجيل',
      message:
          'ستُقفل هذه العملية (${formatEgp(_op.amount)}) وتبقى محفوظة في '
          'السجل كما هي، وتُسجَّل عملية جديدة بمبلغ ${formatEgp(target)} '
          'برقم وترتيب جديدين. إذا تغيّر رصيد الخادم سنستخدم أقصى مبلغ '
          'متاح.',
      confirmLabel: 'تسجيل العملية الجديدة',
    );
    if (!ok) return;

    await _run(() async {
      final serverDebts = await widget.api.fetchDebts(_op.customerId);
      final newPaymentId = await widget.repository.replaceConflictedPayment(
        operationId: _op.operationId,
        serverDebts: serverDebts,
      );
      final newOperation = await widget.repository.getOperationForPayment(
        newPaymentId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSavedView(
            operation: newOperation,
            customerName: customerInfoFor(_op.customerId).name,
            isOnline: widget.network.isOnline,
          ),
        ),
        result: true,
      );
    });
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
      title: 'إلغاء التحصيل',
      message:
          'سيُلغى هذا التحصيل (${formatEgp(_op.amount)}) ويرجع الرصيد '
          'المحلي لما يؤكده الخادم. العملية نفسها تبقى محفوظة في السجل '
          'ولا تُحذف.',
      confirmLabel: 'إلغاء التحصيل',
      danger: true,
    );
    if (!ok) return;

    await _run(() async {
      final serverDebts = await widget.api.fetchDebts(_op.customerId);
      await widget.repository.cancelConflictedPayment(
        operationId: _op.operationId,
        serverDebts: serverDebts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء التحصيل. العملية محفوظة في السجل.'),
        ),
      );
      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = customerInfoFor(_op.customerId).name;
    final serverBalance = _op.conflictServerBalance;
    final exceeds = serverBalance != null && _op.amount > serverBalance;
    final canReplace = serverBalance != null && serverBalance > 0;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'تحصيل يحتاج مراجعتك',
            subtitle: 'ترتيب ${_op.deviceSequence} · ${_op.displayId}',
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exceeds
                        ? 'المبلغ الذي سجّلته أكبر من المتبقي على الخادم'
                        : 'تغيّر رصيد العميل على الخادم أثناء انقطاع اتصالك',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AmountCard(
                    amount: _op.amount,
                    serverBalance: serverBalance,
                    exceeds: exceeds,
                  ),
                  const SizedBox(height: 14),
                  ReasonCard(reasonText: _reason(name)),
                ],
              ),
            ),
          ),
          ConflictBottomActions(
            busy: _busy,
            error: _error,
            canReplace: canReplace,
            exceeds: exceeds,
            serverBalance: serverBalance,
            onReplace: _replace,
            onCancel: _cancel,
          ),
        ],
      ),
    );
  }
}
