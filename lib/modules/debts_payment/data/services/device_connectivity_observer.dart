import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:flutter/widgets.dart';

class DeviceConnectivityObserver with WidgetsBindingObserver {
  DeviceConnectivityObserver({
    required this._network,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final MockNetwork _network;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateNetwork,
      onError: (Object _) => _network.setOnline(false),
    );

    await _refresh();
  }

  void _updateNetwork(List<ConnectivityResult> results) {
    final hasNetwork = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    _network.setOnline(hasNetwork);
  }

  Future<void> _refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateNetwork(results);
    } catch (_) {
      _network.setOnline(false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
  }
}
