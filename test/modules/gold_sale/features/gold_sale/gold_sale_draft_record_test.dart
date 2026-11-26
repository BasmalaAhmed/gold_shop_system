import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_draft_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

GoldSaleCartItem _item(String code, {int price = 420000}) => GoldSaleCartItem(
  code: code,
  status: GoldItemStatus.available,
  input: GoldSaleInput(
    grossWeightMg: 4500,
    stonesWeightMg: 300,
    karat: 21,
    goldPricePerGramPiasters: price,
    laborValue: 12000,
    laborPricingType: LaborPricingType.perGram,
  ),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('draft survives "closing the app" (new repo instance) with fixed price',
      () async {
    final cart = GoldSaleCart()
      ..add(_item('A-1'))
      ..setDiscount(discountPercent: 10)
      ..setTradeIn(
        const TradeInInput(
          karat: 21,
          weightMg: 2000,
          buyPricePerGramPiasters: 400000,
        ),
      );

    await GoldSaleDraftRepo().save(
      GoldSaleDraft(
        items: cart.items,
        discountPercent: cart.discountPercent,
        supervisorApprovalNumber: null,
        tradeIn: cart.tradeIn,
        cashAmountText: '10000',
        otherAmountText: '',
        otherMethod: GoldSalePaymentMethod.card,
      ),
    );

    final loaded = await GoldSaleDraftRepo().load();
    expect(loaded, isNotNull);

    final restored = GoldSaleCart()
      ..restore(
        items: loaded!.items,
        discountPercent: loaded.discountPercent,
        tradeIn: loaded.tradeIn,
      );

    expect(restored.items.single.input.goldPricePerGramPiasters, 420000);
    expect(restored.totalPiasters, cart.totalPiasters);
    expect(restored.amountDuePiasters, cart.amountDuePiasters);
    expect(loaded.cashAmountText, '10000');
  });

  test('recorded sale keeps its prices after the cart prices are refreshed',
      () async {
    final cart = GoldSaleCart()
      ..add(_item('A-1'))
      ..setDiscount(discountPercent: 10);

    final record = GoldSaleRecord.fromCart(
      cart: cart,
      payments: const [
        GoldSalePayment(
          method: GoldSalePaymentMethod.cash,
          amountPiasters: 1815710,
        ),
      ],
      recordedAt: DateTime(2026, 11, 19),
    );
    final before = jsonEncode(record.data);

    final repo = GoldSaleRecordRepo();
    await repo.add(record);

    cart.restore(items: [_item('A-1', price: 500000)], discountPercent: 10);

    expect(cart.totalPiasters, isNot(1815710));
    expect(jsonEncode(record.data), before);
    final stored = await GoldSaleRecordRepo().loadAll();
    expect(stored.single['totalPiasters'], 1815710);
    expect(
      (stored.single['items'] as List).single['goldPricePerGramPiasters'],
      420000,
    );
  });
}