import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_price_repo.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/views/home_view.dart';

void main() {
  runApp(const GoldShopApp());
}

class GoldShopApp extends StatefulWidget {
  const GoldShopApp({super.key});

  @override
  State<GoldShopApp> createState() => _GoldShopAppState();
}

class _GoldShopAppState extends State<GoldShopApp> {

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بيع الذهب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'IBM Plex Sans Arabic'
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeView(
        priceRepository: const GoldSaleDemoPriceRepo(),
      ),
    );
  }
}
