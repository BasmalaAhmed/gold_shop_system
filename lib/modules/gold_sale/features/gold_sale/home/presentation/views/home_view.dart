import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_catalog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_price_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/models/invoice_model.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/calculation_bottom_sheet.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/common/home_app_bar.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/delete_confirm_dialog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/discount_bottom_sheet.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/manual_code_bottom_sheet.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/mobile/mobile_body.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/views/sale_payment_view.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/sale_success_screen.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/scanner_overlay_dialog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/scrap_gold_bottom_sheet.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/tablet/tablet_body.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/labor_pricing_dialog.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.priceRepository});

  final GoldSalePriceRepo priceRepository;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _catalog = const GoldSaleDemoCatalog();
  final _cart = GoldSaleCart();
  final _draftRepository = GoldSaleDraftRepo();
  final _recordRepository = GoldSaleRecordRepo();
  final _paymentValidator = const GoldSalePaymentValidator();
  DateTime? _lastSavedAt;

  bool _isLoadingDraft = true;
  Future<void> _saveQueue = Future<void>.value();

  String _cashAmountText = '';
  String _otherAmountText = '';
  GoldSalePaymentMethod _otherPaymentMethod = GoldSalePaymentMethod.other;

  InvoiceError? _invoiceError;
  bool _isPendingApproval = false;
  bool _isTabletPaymentMode = false;
  int _currentGoldPricePiasters = 420000;
  int _currentBuyPricePiasters = 405000;

  @override
  void initState() {
    super.initState();
    _loadPrices();
    _loadDraft();
  }

  Future<void> _loadPrices() async {
    try {
      final sale = await widget.priceRepository.getSalePricePerGramPiasters(21);
      final buy = await widget.priceRepository.getBuyPricePerGramPiasters(21);
      if (!mounted) return;
      setState(() {
        _currentGoldPricePiasters = sale;
        _currentBuyPricePiasters = buy;
      });
    } catch (_) {}
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await _draftRepository.load();
      if (!mounted) return;
      if (draft != null) {
        setState(() {
          _cart.restore(
            items: draft.items,
            discountPercent: draft.discountPercent,
            supervisorApprovalNumber: draft.supervisorApprovalNumber,
            tradeIn: draft.tradeIn,
          );
          _cashAmountText = draft.cashAmountText;
          _otherAmountText = draft.otherAmountText;
          _otherPaymentMethod = draft.otherMethod;
          _isPendingApproval = draft.discountPercent > 10;
          _lastSavedAt = draft.savedAt;
        });
      }
    } catch (_) {
      if (mounted) _showMessage('تعذر استعادة المسودة المحفوظة.');
    } finally {
      if (mounted) setState(() => _isLoadingDraft = false);
    }
  }

  Future<void> _saveDraft() {
    final draft = GoldSaleDraft(
      items: _cart.items,
      discountPercent: _cart.discountPercent,
      supervisorApprovalNumber: _cart.supervisorApprovalNumber,
      tradeIn: _cart.tradeIn,
      cashAmountText: _cashAmountText,
      otherAmountText: _otherAmountText,
      otherMethod: _otherPaymentMethod,
    );

    _saveQueue = _saveQueue.catchError((_) {}).then<void>((_) async {
      final savedAt = await _draftRepository.save(draft);

      if (!mounted) return;

      setState(() => _lastSavedAt = savedAt);
    });

    return _saveQueue;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addByCode(String code) async {
    if (!mounted) return;
    setState(() => _invoiceError = null);

    final product = _catalog.findByCode(code);
    if (product == null) {
      _showMessage('الكود غير موجود في السجل.');
      return;
    }

    if (product.status != GoldItemStatus.available) {
      setState(() {
        _invoiceError = InvoiceError(
          title: '${product.name} - ${product.status.displayName}',
          subtitle: product.status.unavailableMessage,
        );
      });
      return;
    }

    if (_cart.items.any(
      (e) => e.code.trim().toUpperCase() == product.code.trim().toUpperCase(),
    )) {
      _showMessage('القطعة مضافة بالفعل.');
      return;
    }

    if (_cart.items.length >= 2) {
      _showMessage('يسمح بإضافة قطعتين كحد أقصى.');
      return;
    }

    final int salePrice;
    try {
      salePrice = await widget.priceRepository.getSalePricePerGramPiasters(
        product.karat,
      );
    } catch (_) {
      _showMessage('لا يوجد سعر بيع مسجل لهذا العيار.');
      return;
    }
    if (!mounted) return;

    final selectedLabor = await showLaborPricingDialog(
      context,
      initialType: product.defaultLaborType,
      initialValue: product.defaultLaborValue > 0
          ? product.defaultLaborValue
          : null,
    );

    if (!mounted || selectedLabor == null) return;

    final laborType = selectedLabor.type;
    final laborVal = selectedLabor.value;

    if (!mounted) return;

    final input = GoldSaleInput(
      grossWeightMg: product.grossWeightMg,
      stonesWeightMg: product.stonesWeightMg,
      karat: product.karat,
      goldPricePerGramPiasters: salePrice,
      laborValue: laborVal,
      laborPricingType: laborType,
    );

    setState(() {
      _cart.add(
        GoldSaleCartItem(
          code: product.code,
          name: product.name,
          status: product.status,
          input: input,
        ),
      );
      if (_cart.discountPercent == 0 && product.defaultDiscountPercent > 0) {
        _cart.setDiscount(discountPercent: product.defaultDiscountPercent);
      }
    });
    _saveDraft();
  }

  void _openScanner() {
    ScannerOverlayDialog.show(
      context,
      currentItemCodes: _cart.items.map((i) => i.code).toList(),
      onCodeSelected: (code) => _addByCode(code),
      onManualInputSelected: _openManualCode,
    );
  }

  void _openManualCode() {
    ManualCodeBottomSheet.show(
      context,
      onCodeSubmitted: (code) => _addByCode(code),
      onBackToScanner: _openScanner,
    );
  }

  Future<void> _refreshPrices() async {
    try {
      final sale = await widget.priceRepository.getSalePricePerGramPiasters(21);
      final buy = await widget.priceRepository.getBuyPricePerGramPiasters(21);
      if (!mounted) return;
      _currentGoldPricePiasters = sale;
      _currentBuyPricePiasters = buy;
      if (_cart.items.isNotEmpty) {
        final refreshed = <GoldSaleCartItem>[];
        for (final item in _cart.items) {
          final old = item.input;
          final price = await widget.priceRepository
              .getSalePricePerGramPiasters(old.karat);
          refreshed.add(
            GoldSaleCartItem(
              code: item.code,
              name: item.name,
              status: item.status,
              input: GoldSaleInput(
                grossWeightMg: old.grossWeightMg,
                stonesWeightMg: old.stonesWeightMg,
                karat: old.karat,
                goldPricePerGramPiasters: price,
                laborValue: old.laborValue,
                laborPricingType: old.laborPricingType,
              ),
            ),
          );
        }

        TradeInInput? refreshedTradeIn;
        final trade = _cart.tradeIn;
        if (trade != null) {
          refreshedTradeIn = TradeInInput(
            weightMg: trade.weightMg,
            karat: trade.karat,
            buyPricePerGramPiasters: await widget.priceRepository
                .getBuyPricePerGramPiasters(trade.karat),
            deductionBasisPoints: trade.deductionBasisPoints,
          );
        }

        if (mounted) {
          setState(() {
            _cart.restore(
              items: refreshed,
              discountPercent: _cart.discountPercent,
              supervisorApprovalNumber: _cart.supervisorApprovalNumber,
              tradeIn: refreshedTradeIn,
            );
          });
        }
      } else {
        if (mounted) setState(() {});
      }
      _saveDraft();
      _showMessage('تم تحديث الأسعار.');
    } catch (_) {
      if (mounted) _showMessage('تعذر تحديث الأسعار.');
    }
  }

  Future<void> _applyTradeIn(
    int weightMg,
    int karat,
    int deductionBasisPoints,
  ) async {
    try {
      final buyPrice = await widget.priceRepository.getBuyPricePerGramPiasters(
        karat,
      );
      if (!mounted) return;
      final tradeIn = TradeInInput(
        weightMg: weightMg,
        karat: karat,
        buyPricePerGramPiasters: buyPrice,
        deductionBasisPoints: deductionBasisPoints,
      );
      setState(() => _cart.setTradeIn(tradeIn));
      _saveDraft();
      _showMessage('تم تطبيق البدل.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'بيانات البدل غير صالحة أو قيمته أكبر من أو تساوي الفاتورة.',
        );
      }
    }
  }

  void _openTradeInSheet() {
    ScrapGoldBottomSheet.show(
      context,
      onApply: _applyTradeIn,
      buyPricePerGramPiasters: _currentBuyPricePiasters,
    );
  }

  void _applyDiscount(int percent, String? approvalNumber) {
    try {
      setState(() {
        _isPendingApproval = percent > 10;
        _cart.setDiscount(
          discountPercent: percent,
          supervisorApprovalNumber: approvalNumber,
        );
      });
      _saveDraft();
    } catch (_) {
      _showMessage('الخصم غير صالح.');
    }
  }

  void _openDiscountSheet() {
    DiscountBottomSheet.show(
      context,
      currentDiscountPercent: _cart.discountPercent,
      cart: _cart,
      onApply: _applyDiscount,
    );
  }

  void _confirmDeleteInvoice() {
    DeleteConfirmDialog.show(
      context,
      itemNames: _cart.items
          .map((item) => '${item.name} (${item.code})')
          .toList(),
      onConfirm: () async {
        if (!mounted) return;
        setState(() {
          _cart.clear();
          _invoiceError = null;
          _isPendingApproval = false;
          _isTabletPaymentMode = false;
          _cashAmountText = '';
          _otherAmountText = '';
        });
        await _draftRepository.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'تم حذف الفاتورة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
          );
        }
      },
    );
  }

  Future<void> _completeSale(List<GoldSalePayment> payments) async {
    _paymentValidator.validate(
      amountDuePiasters: _cart.amountDuePiasters,
      payments: payments,
    );

    for (final item in _cart.items) {
      final current = _catalog.findByCode(item.code);
      if (current == null || current.status != GoldItemStatus.available) {
        _showMessage('القطعة ${item.code} لم تعد متاحة للبيع.');
        throw StateError('Item unavailable');
      }
    }

    final record = GoldSaleRecord.fromCart(
      cart: _cart,
      payments: payments,
      recordedAt: DateTime.now(),
    );

    await _saveQueue;
    await _recordRepository.add(record);
    await _draftRepository.clear();
  }

  Future<void> _onTabletPaymentConfirmed(List<GoldSalePayment> payments) async {
    final amountDue = _cart.amountDuePiasters;
    final cashPaid = payments
        .firstWhere(
          (p) => p.method == GoldSalePaymentMethod.cash,
          orElse: () => const GoldSalePayment(
            method: GoldSalePaymentMethod.cash,
            amountPiasters: 0,
          ),
        )
        .amountPiasters;
    final secPayment = payments.firstWhere(
      (p) => p.method != GoldSalePaymentMethod.cash,
      orElse: () => const GoldSalePayment(
        method: GoldSalePaymentMethod.other,
        amountPiasters: 0,
      ),
    );

    await _completeSale(payments);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SaleSuccessScreen(
          amountDuePiasters: amountDue,
          cashPaidPiasters: cashPaid,
          secondaryPaidPiasters: secPayment.amountPiasters,
          secondaryMethodName: 'إنستاباي',
          goldPricePiasters: _currentGoldPricePiasters,
          onNewInvoice: () {
            if (mounted) {
              setState(() {
                _cart.clear();
                _isTabletPaymentMode = false;
                _invoiceError = null;
                _isPendingApproval = false;
              });
            }
          },
        ),
      ),
    );
  }

  void _showCalculation(int index) {
    CalculationBottomSheet.show(
      context,
      item: _cart.items[index],
      result: _cart.lineResults[index],
      discountPercent: _cart.discountPercent,
    );
  }

  void _removeItem(String code) {
    setState(() => _cart.removeByCode(code));
    _saveDraft();
  }

  void _openPaymentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SalePaymentView(
          amountDuePiasters: _cart.amountDuePiasters,
          currentGoldPricePiasters: _currentGoldPricePiasters,
          onCompleteSale: _completeSale,
          onNewInvoice: () {
            if (!mounted) return;

            setState(() {
              _cart.clear();
              _invoiceError = null;
              _isPendingApproval = false;
            });
          },
        ),
      ),
    );
  }

  void _cancelPendingDiscount() {
    setState(() {
      _isPendingApproval = false;
      _cart.setDiscount(discountPercent: 10);
    });

    _saveDraft();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 720;

        return Scaffold(
          backgroundColor: UnifiedTheme.background,
          appBar: HomeAppBar(
            isTablet: isTablet,
            goldPriceEgp: _currentGoldPricePiasters / 100.0,
            buyPriceEgp: _currentBuyPricePiasters / 100.0,
            onRefresh: _refreshPrices,
            lastSavedAt: _lastSavedAt,
            onSaveDraft: () async {
              try {
                await _saveDraft();

                if (mounted) {
                  _showMessage('تم حفظ المسودة بنجاح.');
                }

                return true;
              } catch (_) {
                if (mounted) {
                  _showMessage('تعذر حفظ المسودة.');
                }

                return false;
              }
            },
            onDeleteInvoice: _confirmDeleteInvoice,
          ),
          body: _isLoadingDraft
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: isTablet
                      ? TabletBody(
                          cart: _cart,
                          isPendingApproval: _isPendingApproval,
                          isPaymentMode: _isTabletPaymentMode,
                          invoiceError: _invoiceError,
                          onPayPressed: () {
                            setState(() => _isTabletPaymentMode = true);
                          },
                          onBackToInvoice: () {
                            setState(() => _isTabletPaymentMode = false);
                          },
                          onCancelPendingDiscount: _cancelPendingDiscount,
                          onConfirmPayment: _onTabletPaymentConfirmed,
                          onShowCalculation: _showCalculation,
                          onEditDiscount: _openDiscountSheet,
                          onRemove: _removeItem,
                          onOpenScanner: _openScanner,
                          onOpenManualCode: _openManualCode,
                          onOpenTradeIn: _openTradeInSheet,
                        )
                      : MobileBody(
                          cart: _cart,
                          goldPriceEgp: _currentGoldPricePiasters / 100.0,
                          isPendingApproval: _isPendingApproval,
                          invoiceError: _invoiceError,
                          onRefreshPrices: _refreshPrices,
                          onOpenScanner: _openScanner,
                          onOpenManualCode: _openManualCode,
                          onShowCalculation: _showCalculation,
                          onEditDiscount: _openDiscountSheet,
                          onRemove: _removeItem,
                          onAddTradeIn: _openTradeInSheet,
                          onCancelPending: _cancelPendingDiscount,
                          onPay: _openPaymentScreen,
                        ),
                ),
        );
      },
    );
  }
}
