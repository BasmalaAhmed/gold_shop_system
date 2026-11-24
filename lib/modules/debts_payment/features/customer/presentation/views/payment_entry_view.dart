import 'package:gold_shop_app/modules/debts_payment/core/customers/customer_info.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/input/amount_input.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/data/repos/payment_repo.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/views/payment_saved_view.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/keypad_section.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/payment_entry_body.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/payment_header.dart';
import 'package:flutter/material.dart';

class PaymentEntryView extends StatefulWidget {
  const PaymentEntryView({
    super.key,
    required this.customerId,
    required this.repository,
    required this.debts,
    required this.network,
    this.onSaved,
  });

  final String customerId;
  final PaymentRepo repository;
  final List<DebtBalance> debts;
  final MockNetwork network;
  final VoidCallback? onSaved;

  @override
  State<PaymentEntryView> createState() => _PaymentEntryViewState();
}

class _PaymentEntryViewState extends State<PaymentEntryView> {
  String _raw = '';
  bool _isSaving = false;
  String? _saveError;

  int get _available =>
      widget.debts.fold<int>(0, (t, d) => t + d.localOutstanding);

  int get _unconfirmed => widget.debts.fold<int>(
    0,
    (t, d) => t + d.pendingAmount + d.conflictAmount,
  );

  int? get _amount {
    final value = parseEgpAmount(_raw);
    return (value == null || value <= 0) ? null : value;
  }

  bool get _exceeds {
    final amount = _amount;
    return amount != null && amount > _available;
  }

  bool get _canSave => _amount != null && !_exceeds && !_isSaving;

  void _onKey(String key) {
    if (_isSaving) return;
    setState(() {
      _raw = applyKey(_raw, key);
      _saveError = null;
    });
  }

  void _setAmount(int piastres) {
    if (_isSaving) return;
    setState(() {
      _raw = piastresToRaw(piastres);
      _saveError = null;
    });
  }

  Future<void> _save() async {
    final amount = _amount;
    if (!_canSave || amount == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final deviceId = await widget.repository.getOrCreateDeviceId();
      final paymentId = await widget.repository.recordPayment(
        customerId: widget.customerId,
        amount: amount,
        deviceId: deviceId,
      );

      final operation = await widget.repository.getOperationForPayment(
        paymentId,
      );

      widget.onSaved?.call();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSavedView(
            operation: operation,
            customerName: customerInfoFor(widget.customerId).name,
            isOnline: widget.network.isOnline,
          ),
        ),
        result: true,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error is StateError
            ? 'المبلغ أكبر من المتبقي المحلي. حدّث الشاشة وجرّب تاني.'
            : 'تعذّر حفظ التحصيل: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = customerInfoFor(widget.customerId);

    return Scaffold(
      body: Column(
        children: [
          PaymentHeader(
            title: 'تحصيل من ${info.firstName}',
            network: widget.network,
          ),
          Expanded(
            child: PaymentEntryBody(
              amount: _amount,
              available: _available,
              unconfirmed: _unconfirmed,
              exceeds: _exceeds,
              debts: widget.debts,
              customerFirstName: info.firstName,
              onSelectAmount: _setAmount,
            ),
          ),
          KeypadSection(
            amount: _amount,
            isSaving: _isSaving,
            canSave: _canSave,
            saveError: _saveError,
            onSave: _save,
            onKey: _onKey,
          ),
        ],
      ),
    );
  }
}
