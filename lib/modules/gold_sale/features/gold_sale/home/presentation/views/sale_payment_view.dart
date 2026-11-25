import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_failure.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/sale_success_screen.dart';

class SalePaymentView extends StatefulWidget {
  const SalePaymentView({
    super.key,
    required this.amountDuePiasters,
    required this.currentGoldPricePiasters,
    required this.onCompleteSale,
    required this.onNewInvoice,
  });

  final int amountDuePiasters;
  final int currentGoldPricePiasters;
  final Future<void> Function(List<GoldSalePayment> payments) onCompleteSale;
  final VoidCallback onNewInvoice;

  @override
  State<SalePaymentView> createState() => _SalePaymentViewState();
}

class _SalePaymentViewState extends State<SalePaymentView> {
  late TextEditingController _cashController;
  late int _cashPaidPiasters;
  GoldSalePaymentMethod _secondaryMethod = GoldSalePaymentMethod.other;

  final Map<GoldSalePaymentMethod, String> _methodLabels = {
    GoldSalePaymentMethod.other: 'إنستاباي',
    GoldSalePaymentMethod.mobileWallet: 'فودافون كاش',
    GoldSalePaymentMethod.card: 'كارت',
    GoldSalePaymentMethod.bankTransfer: 'تحويل',
  };

  @override
  void initState() {
    super.initState();
    final defaultCash = widget.amountDuePiasters > 500000
        ? 500000
        : widget.amountDuePiasters;
    _cashPaidPiasters = defaultCash;
    _cashController = TextEditingController(
      text: PriceFormatter.formatPiasters(_cashPaidPiasters),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  int get _remainingPiasters => (widget.amountDuePiasters - _cashPaidPiasters)
      .clamp(0, widget.amountDuePiasters);

  bool _isSubmitting = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final payments = <GoldSalePayment>[];
    if (_cashPaidPiasters > 0) {
      payments.add(
        GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: _cashPaidPiasters,
        ),
      );
    }
    if (_remainingPiasters > 0) {
      payments.add(
        GoldSalePayment(
          method: _secondaryMethod,
          amountPiasters: _remainingPiasters,
        ),
      );
    }

    final validationError = const GoldSalePaymentValidator().errorMessage(
      amountDuePiasters: widget.amountDuePiasters,
      payments: payments,
    );
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onCompleteSale(payments);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SaleSuccessScreen(
            amountDuePiasters: widget.amountDuePiasters,
            cashPaidPiasters: _cashPaidPiasters,
            secondaryPaidPiasters: _remainingPiasters,
            secondaryMethodName: _methodLabels[_secondaryMethod] ?? 'إنستاباي',
            goldPricePiasters: widget.currentGoldPricePiasters,
            onNewInvoice: widget.onNewInvoice,
          ),
        ),
      );
      return;
    } on GoldSaleFailure catch (failure) {
      _showError(failure.message);
    } catch (_) {
      _showError('تعذر تسجيل الفاتورة. حاول مرة أخرى.');
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final amountDueEgp = PriceFormatter.formatPiasters(
      widget.amountDuePiasters,
    );

    final remainingEgp = PriceFormatter.formatPiasters(_remainingPiasters);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الدفع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: UnifiedTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: UnifiedTheme.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'المطلوب',
                      style: TextStyle(
                        fontSize: 13,
                        color: UnifiedTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$amountDueEgp ج.م',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: UnifiedTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'كاش',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: UnifiedTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _cashController,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        final valD =
                            double.tryParse(val.replaceAll(',', '').trim()) ??
                            0.0;
                        setState(() {
                          _cashPaidPiasters = (valD * 100).round();
                        });
                      },
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'ج.م',
                            style: TextStyle(color: UnifiedTheme.textSecondary),
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: UnifiedTheme.textSecondary,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: UnifiedTheme.teal,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: UnifiedTheme.textSecondary,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: UnifiedTheme.teal,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildQuickChip('الكل كاش', widget.amountDuePiasters),
                        const SizedBox(width: 8),
                        _buildQuickChip('5,000', 500000),
                        const SizedBox(width: 8),
                        _buildQuickChip('2,000', 200000),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الباقي $remainingEgp يُدفع بـ:',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _methodLabels.entries.toList().map((entry) {
                        final isSelected = _secondaryMethod == entry.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _secondaryMethod = entry.key),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? UnifiedTheme.teal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? UnifiedTheme.teal
                                      : UnifiedTheme.textSecondary,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : UnifiedTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المتبقي',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: UnifiedTheme.emerald,
                      ),
                    ),
                    Text(
                      '$remainingEgp ج.م',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UnifiedTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'تأكيد وتسجيل الفاتورة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UnifiedTheme.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int valuePiasters) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cashPaidPiasters = valuePiasters.clamp(0, widget.amountDuePiasters);
          _cashController.text = PriceFormatter.formatPiasters(
            _cashPaidPiasters,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
