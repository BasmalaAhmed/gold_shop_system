import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/shop_approval/app/shop_approval_app.dart';
import 'package:gold_shop_app/modules/shop_approval/core/connectivity/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connectivity = ConnectivityPlusService();
  await connectivity.init();
  runApp(ShopApprovalApp(connectivity: connectivity));
}
