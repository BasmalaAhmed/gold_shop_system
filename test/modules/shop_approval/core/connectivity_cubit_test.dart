import 'package:flutter_test/flutter_test.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_cubit.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_service.dart';

void main() {
  test('follows connectivity changes', () async {
    final service = FakeConnectivityService();
    final cubit = ConnectivityCubit(service);
    addTearDown(cubit.close);

    expect(cubit.state, isTrue);

    service.setOnline(false);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isFalse);
  });
}
