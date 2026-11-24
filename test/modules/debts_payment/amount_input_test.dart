import 'package:gold_shop_app/modules/debts_payment/core/input/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

String _type(String keys) {
  var raw = '';
  for (final k in keys.split(' ')) {
    raw = applyKey(raw, k);
  }
  return raw;
}

void main() {
  test('builds digits and allows two decimals only', () {
    expect(_type('1 . 5 0'), '1.50');
    expect(_type('1 . 5 0 5'), '1.50');
  });

  test('dot on empty becomes 0. and second dot is ignored', () {
    expect(_type('.'), '0.');
    expect(_type('1 . . 5'), '1.5');
  });

  test('no leading zeros', () {
    expect(_type('0 5'), '5');
    expect(_type('0 0'), '0');
  });

  test('backspace removes last char and is safe on empty', () {
    expect(_type('1 2 back'), '1');
    expect(_type('back'), '');
  });

  test('caps the length', () {
    expect(_type('1 2 3 4 5 6 7 8 9 0 1').length, 9);
  });
}