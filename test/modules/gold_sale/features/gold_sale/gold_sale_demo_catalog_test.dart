import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_catalog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';

void main() {
  group('GoldSaleDemoCatalog', () {
    final catalog = GoldSaleDemoCatalog();

    test('finds an item by code regardless of spaces or letter case', () {
      final item = catalog.findByCode(' demo-1001 ');

      expect(item, isNotNull);
      expect(item!.code, 'DEMO-1001');
      expect(item.status, GoldItemStatus.available);
    });

    test('returns reserved status from the item record', () {
      final item = catalog.findByCode('DEMO-1003');

      expect(item, isNotNull);
      expect(item!.status, GoldItemStatus.reserved);
    });

    test('returns null for an unknown code', () {
      expect(catalog.findByCode('UNKNOWN'), isNull);
    });
  });
}