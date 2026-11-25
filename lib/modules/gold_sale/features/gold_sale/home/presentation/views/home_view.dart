import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_catalog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_failure.dart';
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
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_cubit.dart';
import 'package:gold_shop_app/modules/shop_approval/features/approvals/presentation/manager/approval_requests_cubit/approval_requests_state.dart';
import 'package:gold_shop_app/modules/shop_approval/models/approval_request.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.priceRepository});

  final GoldSalePriceRepo priceRepository;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int? _pendingApprovalRequestId;
  bool _isAddingItem = false;
  final _catalog = GoldSaleDemoCatalog();
  final _cart = GoldSaleCart();
  final _draftRepository = GoldSaleDraftRepo();
  final _recordRepository = GoldSaleRecordRepo();
  final _paymentValidator = const GoldSalePaymentValidator();
  DateTime? _lastSavedAt;
  bool _isSendingApprovalRequest = false;
  bool _isLoadingDraft = true;
  Future<void> _saveQueue = Future<void>.value();
  String _cashAmountText = '';
  String _otherAmountText = '';
  GoldSalePaymentMethod _otherPaymentMethod = GoldSalePaymentMethod.other;
  bool _isCompletingSale = false;
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
        final approvalNum = draft.supervisorApprovalNumber?.trim() ?? '';
        final parsedReqId = approvalNum.startsWith('REQ-')
            ? int.tryParse(approvalNum.substring(4))
            : null;
        final pendingId = draft.pendingApprovalRequestId ?? parsedReqId;
        final isPending =
            draft.discountPercent > 10 &&
            (pendingId != null || approvalNum.startsWith('REQ-'));

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
          _pendingApprovalRequestId = isPending ? pendingId : null;
          _isPendingApproval = isPending;
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
      pendingApprovalRequestId: _isPendingApproval
          ? _pendingApprovalRequestId
          : null,
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
    if (_isAddingItem) return;
    _isAddingItem = true;
    try {
      await _addByCodeInternal(code);
    } finally {
      _isAddingItem = false;
    }
  }

  Future<void> _addByCodeInternal(String code) async {
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

    try {
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
    } catch (_) {
      _showMessage('تعذر إضافة القطعة إلى الفاتورة.');
      return;
    }
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

      if (_cart.items.isEmpty) {
        setState(() {
          _currentGoldPricePiasters = sale;
          _currentBuyPricePiasters = buy;
        });
        _showMessage('تم تحديث الأسعار.');
        return;
      }

      final refreshed = <GoldSaleCartItem>[];
      for (final item in _cart.items) {
        final old = item.input;
        final price = await widget.priceRepository.getSalePricePerGramPiasters(
          old.karat,
        );
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

      if (!mounted) return;

      try {
        setState(() {
          _cart.restore(
            items: refreshed,
            discountPercent: _cart.discountPercent,
            supervisorApprovalNumber: _cart.supervisorApprovalNumber,
            tradeIn: refreshedTradeIn,
          );
          _currentGoldPricePiasters = sale;
          _currentBuyPricePiasters = buy;
        });
      } catch (_) {
        _showMessage(
          'تعذر تحديث الأسعار لأن قيمة البدل ستتجاوز إجمالي الفاتورة.',
        );
        return;
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

  Future<void> _applyDiscount(int percent, String? approvalNumber) async {
    if (percent <= 10) {
      try {
        _cart.setDiscount(discountPercent: percent);
      } catch (_) {
        _showMessage('الخصم غير صالح أو يجعل المطلوب أقل من قيمة البدل.');
        return;
      }
      setState(() {
        _isPendingApproval = false;
        _pendingApprovalRequestId = null;
      });
      _saveDraft();
      return;
    }

    if (_isSendingApprovalRequest) return;

    final previousPercent = _cart.discountPercent;
    final previousApproval = _cart.supervisorApprovalNumber;

    try {
      _cart.setDiscount(
        discountPercent: percent,
        supervisorApprovalNumber: 'Pending',
      );
    } catch (_) {
      _showMessage('الخصم غير صالح أو يجعل المطلوب أقل من قيمة البدل.');
      return;
    }

    final itemsLabel = _cart.items
        .map((e) => '${e.name} (${e.code})')
        .join('، ');
    final discountAmount = _cart.lineResults.fold<int>(
      0,
      (sum, r) => sum + r.discountPiasters,
    );

    setState(() => _isSendingApprovalRequest = true);

    ApprovalRequest? created;
    try {
      created = await context
          .read<ApprovalRequestsCubit>()
          .submitDiscountApprovalRequest(
            employeeName: 'كاشير المبيعات',
            branchName: 'فرع المهندسين',
            amountInPiastres: discountAmount,
            reason: 'طلب خصم $percent% على $itemsLabel',
          );
    } finally {
      if (mounted) setState(() => _isSendingApprovalRequest = false);
    }

    if (!mounted) return;

    if (created == null) {
      setState(() {
        _cart.setDiscount(
          discountPercent: previousPercent,
          supervisorApprovalNumber: previousApproval,
        );
      });
      _showMessage('تعذر إرسال طلب الموافقة.');
      return;
    }

    final requestId = created.requestId;

    setState(() {
      _pendingApprovalRequestId = requestId;
      _isPendingApproval = true;
      _cart.setDiscount(
        discountPercent: percent,
        supervisorApprovalNumber: 'REQ-$requestId',
      );
    });
    _saveDraft();
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
          _pendingApprovalRequestId = null;
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
    if (_isCompletingSale) {
      throw const GoldSaleFailure('جاري تسجيل الفاتورة، انتظر لحظة.');
    }
    if (_isPendingApproval) {
      throw const GoldSaleFailure('الخصم بانتظار موافقة صاحب المحل.');
    }
    if (_cart.items.isEmpty) {
      throw const GoldSaleFailure('الفاتورة فارغة.');
    }

    final paymentError = _paymentValidator.errorMessage(
      amountDuePiasters: _cart.amountDuePiasters,
      payments: payments,
    );
    if (paymentError != null) throw GoldSaleFailure(paymentError);

    for (final item in _cart.items) {
      final current = _catalog.findByCode(item.code);
      if (current == null || current.status != GoldItemStatus.available) {
        throw GoldSaleFailure('القطعة ${item.code} لم تعد متاحة للبيع.');
      }
    }

    _isCompletingSale = true;
    try {
      final record = GoldSaleRecord.fromCart(
        cart: _cart,
        payments: payments,
        recordedAt: DateTime.now(),
      );

      try {
        await _saveQueue;
      } catch (_) {}

      await _recordRepository.add(record);
      await _draftRepository.clear();

      for (final item in _cart.items) {
        _catalog.markSold(item.code);
      }

      if (mounted) {
        setState(() {
          _cart.clear();
          _invoiceError = null;
          _isPendingApproval = false;
          _pendingApprovalRequestId = null;
          _isTabletPaymentMode = false;
          _cashAmountText = '';
          _otherAmountText = '';
        });
      }
    } finally {
      _isCompletingSale = false;
    }
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
          secondaryMethodName: secPayment.method.arabicLabel,
          goldPricePiasters: _currentGoldPricePiasters,
          onNewInvoice: () {
            if (mounted) {
              setState(() {
                _cart.clear();
                _isTabletPaymentMode = false;
                _invoiceError = null;
                _isPendingApproval = false;
                _pendingApprovalRequestId = null;
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
              _pendingApprovalRequestId = null;
            });
          },
        ),
      ),
    );
  }

  void _cancelPendingDiscount() {
    setState(() {
      _isPendingApproval = false;
      _pendingApprovalRequestId = null;
      _cart.setDiscount(discountPercent: 10);
    });
    _saveDraft();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ApprovalRequestsCubit, ApprovalRequestsState>(
      listener: (context, state) {
        final requestId = _pendingApprovalRequestId;
        if (requestId == null || state is! ApprovalRequestsSuccess) return;

        final req = state.requests
            .where((r) => r.requestId == requestId)
            .firstOrNull;

        if (req == null) {
          _cancelPendingDiscount();
          _showMessage('طلب الموافقة لم يعد موجودًا، تم الرجوع إلى 10%.');
          return;
        }

        if (req.status == ApprovalStatus.approved) {
          setState(() {
            _isPendingApproval = false;
            _pendingApprovalRequestId = null;
            _cart.setDiscount(
              discountPercent: _cart.discountPercent,
              supervisorApprovalNumber: 'APR-${req.requestId}',
            );
          });
          _saveDraft();
          final isTablet = MediaQuery.of(context).size.width >= 720;
          if (isTablet) {
            setState(() => _isTabletPaymentMode = true);
          } else {
            _openPaymentScreen();
          }
        } else if (req.status == ApprovalStatus.rejected) {
          _cancelPendingDiscount();
          _showMessage('تم رفض طلب الخصم، تم الرجوع إلى 10%.');
        }
      },
      child: LayoutBuilder(
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
      ),
    );
  }
}
