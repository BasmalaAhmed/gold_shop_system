import 'package:flutter/material.dart';
import 'package:gold_shop_app/app/unified_app.dart';
import 'package:gold_shop_app/app/unified_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await UnifiedDependencies.create();

  runApp(UnifiedGoldShopApp(dependencies: dependencies));
}
