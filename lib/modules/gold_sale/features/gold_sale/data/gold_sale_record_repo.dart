import 'dart:convert';

import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldSaleRecordRepo {
  GoldSaleRecordRepo({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'gold_sale_records_v1';

  final SharedPreferencesAsync _preferences;

  Future<List<Map<String, dynamic>>> loadAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> add(GoldSaleRecord record) async {
    final all = await loadAll();
    all.add(record.data);
    await _preferences.setString(_key, jsonEncode(all));
  }
}