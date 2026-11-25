import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';

import 'gold_sale_calc.dart';

class GoldSaleCartItem {
  const GoldSaleCartItem({
    required this.code,
    required this.input,
    required this.status,
    this.name = 'قطعة ذهب',
  });

  final String code;
  final GoldSaleInput input;
  final GoldItemStatus status;
  final String name;
}

class GoldSaleCart {
  final GoldSaleCalc _calculator = const GoldSaleCalc();
  final List<GoldSaleCartItem> _items = [];
  int get discountPercent => _discountPercent;
  String? get supervisorApprovalNumber => _supervisorApprovalNumber;

  List<GoldSaleCartItem> get items => List.unmodifiable(_items);

  List<GoldSaleLineResult> get lineResults => List.unmodifiable(
    _items.map(
      (item) => _calculator.calculate(
        item.input,
        discountPercent: _discountPercent,
        supervisorApprovalNumber: _supervisorApprovalNumber,
      ),
    ),
  );

  int get totalPiasters =>
      lineResults.fold(0, (total, line) => total + line.totalPiasters);

  TradeInInput? _tradeIn;
  TradeInInput? get tradeIn => _tradeIn;

  int get tradeInValuePiasters => _tradeIn == null
      ? 0
      : const TradeInCalc().calculate(_tradeIn!).valuePiasters;

  int get amountDuePiasters => totalPiasters - tradeInValuePiasters;

  void setTradeIn(TradeInInput? tradeIn) {
    if (tradeIn != null) {
      final value = const TradeInCalc().calculate(tradeIn).valuePiasters;
      if (value >= totalPiasters) {
        throw ArgumentError('Trade-in must be less than the invoice total.');
      }
    }
    _tradeIn = tradeIn;
  }

  void clear() {
    _items.clear();
    _discountPercent = 0;
    _supervisorApprovalNumber = null;
    _tradeIn = null;
  }

  void add(GoldSaleCartItem item) {
    final normalizedCode = _normalizeCode(item.code);

    if (normalizedCode.isEmpty) {
      throw ArgumentError('Item code cannot be empty.');
    }

    if (item.status != GoldItemStatus.available) {
      throw StateError('This item is not available for a normal sale.');
    }

    final alreadyAdded = _items.any(
      (existing) => _normalizeCode(existing.code) == normalizedCode,
    );

    if (alreadyAdded) {
      throw StateError('This item is already in the sale.');
    }

    if (_items.length >= 2) {
      throw StateError('A sale can contain at most two items.');
    }
    _calculator.calculate(
      item.input,
      discountPercent: _discountPercent,
      supervisorApprovalNumber: _supervisorApprovalNumber,
    );

    _items.add(item);
  }

  void removeByCode(String code) {
    final normalizedCode = _normalizeCode(code);

    _items.removeWhere((item) => _normalizeCode(item.code) == normalizedCode);

    if (_items.isEmpty ||
        (_tradeIn != null && tradeInValuePiasters >= totalPiasters)) {
      _tradeIn = null;
    }
  }

  String _normalizeCode(String code) => code.trim().toUpperCase();

  int _discountPercent = 0;
  String? _supervisorApprovalNumber;

  void checkDiscount({
    required int discountPercent,
    String? supervisorApprovalNumber,
  }) {
    final approvalNumber = supervisorApprovalNumber?.trim();

    _calculator.validateDiscount(
      discountPercent: discountPercent,
      supervisorApprovalNumber: approvalNumber,
    );

    var newTotalPiasters = 0;
    for (final item in _items) {
      newTotalPiasters += _calculator
          .calculate(
            item.input,
            discountPercent: discountPercent,
            supervisorApprovalNumber: approvalNumber,
          )
          .totalPiasters;
    }

    if (_tradeIn != null && tradeInValuePiasters >= newTotalPiasters) {
      throw ArgumentError(
        'Discount makes the total less than or equal to the trade-in value.',
      );
    }
  }

  void setDiscount({
    required int discountPercent,
    String? supervisorApprovalNumber,
  }) {
    final approvalNumber = supervisorApprovalNumber?.trim();

    checkDiscount(
      discountPercent: discountPercent,
      supervisorApprovalNumber: approvalNumber,
    );

    _supervisorApprovalNumber = approvalNumber == null || approvalNumber.isEmpty
        ? null
        : approvalNumber;
    _discountPercent = discountPercent;
  }

  void restore({
    required List<GoldSaleCartItem> items,
    required int discountPercent,
    String? supervisorApprovalNumber,
    TradeInInput? tradeIn,
  }) {
    final restoredCart = GoldSaleCart();

    for (final item in items) {
      restoredCart.add(item);
    }

    restoredCart.setDiscount(
      discountPercent: discountPercent,
      supervisorApprovalNumber: supervisorApprovalNumber,
    );
    restoredCart.setTradeIn(tradeIn);

    _items
      ..clear()
      ..addAll(restoredCart._items);

    _discountPercent = restoredCart._discountPercent;
    _supervisorApprovalNumber = restoredCart._supervisorApprovalNumber;
    _tradeIn = restoredCart._tradeIn;
  }
}
