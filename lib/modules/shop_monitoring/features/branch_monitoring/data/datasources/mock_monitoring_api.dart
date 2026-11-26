import 'dart:async';
import 'dart:math';

import 'package:gold_shop_app/modules/shop_monitoring/core/errors/network_exception.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/datasources/connectivity_service.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/datasources/gold_price_api.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/datasources/monitoring_api.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/branch_model.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/gold_price_model.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/monitoring_snapshot_model.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/monitoring_update_model.dart';
import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/data/models/recent_operation_model.dart';

const String allScope = 'all';

class MockMonitoringApi implements MonitoringApi, GoldPriceApi {
  MockMonitoringApi({
    required this.connectivity,
    List<BranchModel>? branches,
    Random? random,
  }) : _branches = branches ?? defaultBranches,
       _random = random ?? Random() {
    _initialize();
  }

  static const List<BranchModel> defaultBranches = [
    BranchModel(id: 'a1', name: 'فرع القاهرة'),
    BranchModel(id: 'a2', name: 'فرع الإسكندرية'),
    BranchModel(id: 'a3', name: 'فرع المنصورة'),
  ];

  final ConnectivityService connectivity;
  final Random _random;
  final List<BranchModel> _branches;

  final Map<String, _ScopeState> _scopes = {};

  final _updateControllers =
      <String, StreamController<MonitoringUpdateModel>>{};

  final _goldController = StreamController<GoldPriceModel>.broadcast();

  late GoldPriceModel _goldPrice;

  Timer? _timer;
  Timer? _goldTimer;
  int _operationCounter = 0;

  void _initialize() {
    var totalSales = 0;
    var totalCash = 0;

    for (final branch in _branches) {
      final sales = 100000 + _random.nextInt(50000);
      final cash = 40000 + _random.nextInt(20000);

      _scopes[branch.id] = _ScopeState(sales: sales, cash: cash);

      totalSales += sales;
      totalCash += cash;
    }

    _scopes[allScope] = _ScopeState(sales: totalSales, cash: totalCash);

    _goldPrice = GoldPriceModel(
      value: 4000,
      sequence: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<BranchModel>> fetchBranches() async {
    await _simulateNetworkDelay();

    return List.unmodifiable(_branches);
  }

  @override
  Future<MonitoringSnapshotModel> fetchSnapshot(String scopeId) async {
    await _simulateNetworkDelay(
      delay: scopeId == _branches.first.id ? _slowScopeDelay : _defaultDelay,
    );

    final state = _scopes[scopeId];

    if (state == null) {
      throw ArgumentError('Unknown scope: $scopeId');
    }

    return MonitoringSnapshotModel(
      scopeId: scopeId,
      sequence: state.sequence,
      totalSales: state.sales,
      totalCash: state.cash,
      operations: List.unmodifiable(state.operations),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Stream<MonitoringUpdateModel> updates(String scopeId) {
    if (!_scopes.containsKey(scopeId)) {
      throw ArgumentError('Unknown scope: $scopeId');
    }

    return _updateControllers
        .putIfAbsent(
          scopeId,
          () => StreamController<MonitoringUpdateModel>.broadcast(),
        )
        .stream;
  }

  @override
  Future<GoldPriceModel> fetchGoldPrice() async {
    await _simulateNetworkDelay();
    return _goldPrice;
  }

  @override
  Stream<GoldPriceModel> goldPriceUpdates() {
    return _goldController.stream;
  }

  static const Duration _defaultDelay = Duration(milliseconds: 300);
  static const Duration defaultOperationEvery = Duration(seconds: 20);
  static const Duration defaultGoldPriceEvery = Duration(minutes: 10);
  static const Duration _slowScopeDelay = Duration(seconds: 2);

  Future<void> _simulateNetworkDelay({Duration delay = _defaultDelay}) async {
    await Future<void>.delayed(delay);

    if (!connectivity.isOnline) {
      throw const NetworkException();
    }
  }

void startSimulation({
  Duration every = defaultOperationEvery,
  Duration? goldPriceEvery = defaultGoldPriceEvery,
}) {
  _timer?.cancel();
  _goldTimer?.cancel();

  _timer = Timer.periodic(every, (_) => _tick());

  if (goldPriceEvery != null) {
    _goldTimer = Timer.periodic(goldPriceEvery, (_) => _updateGoldPrice());
  }
}

void _tick() {
  if (!connectivity.isOnline) return;

  final branch = _branches[_random.nextInt(_branches.length)];

  final amount = (1 + _random.nextInt(20)) * 500;
  final now = DateTime.now().toUtc();

  final operation = RecentOperationModel(
    id: 'op-${++_operationCounter}',
    title: 'بيع ذهب - ${branch.name}',
    amount: amount,
    at: now,
  );

  _applySale(branch.id, amount, amount, operation, now);
  _applySale(allScope, amount, amount, operation, now);
}

void recordSale({
  required String branchId,
  required int salesAmount,
  required int cashAmount,
  String? itemsLabel,
}) {
  final branch = _branches.where((b) => b.id == branchId).firstOrNull;

  if (branch == null) {
    throw ArgumentError('Unknown branch: $branchId');
  }

  final now = DateTime.now().toUtc();
  final label = (itemsLabel == null || itemsLabel.isEmpty)
      ? ''
      : ' ($itemsLabel)';

  final operation = RecentOperationModel(
    id: 'op-${++_operationCounter}',
    title: 'بيع ذهب$label - ${branch.name}',
    amount: salesAmount,
    at: now,
  );

  _applySale(branch.id, salesAmount, cashAmount, operation, now);
  _applySale(allScope, salesAmount, cashAmount, operation, now);
}

void _applySale(
  String scopeId,
  int salesDelta,
  int cashDelta,
  RecentOperationModel operation,
  DateTime now,
) {
  final state = _scopes[scopeId]!;

  state.sequence++;
  state.sales += salesDelta;
  state.cash += cashDelta;

  state.operations.insert(0, operation);

  if (state.operations.length > 20) {
    state.operations.removeLast();
  }

  final update = MonitoringUpdateModel(
    scopeId: scopeId,
    sequence: state.sequence,
    salesDelta: salesDelta,
    cashDelta: cashDelta,
    createdAt: now,
    operation: operation,
  );

  final controller = _updateControllers[scopeId];

  if (controller != null && controller.hasListener) {
    controller.add(update);
  }
}

void _updateGoldPrice() {
  if (!connectivity.isOnline) return;
  final change = _random.nextInt(21) - 10;

  _goldPrice = GoldPriceModel(
    value: _goldPrice.value + change,
    sequence: _goldPrice.sequence + 1,
    updatedAt: DateTime.now().toUtc(),
  );

  if (_goldController.hasListener) {
    _goldController.add(_goldPrice);
  }
}

void dispose() {
  _timer?.cancel();
  _goldTimer?.cancel();

  for (final controller in _updateControllers.values) {
    controller.close();
  }

  _goldController.close();
}
}

class _ScopeState {
  _ScopeState({required this.sales, required this.cash});

  int sequence = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  int sales;
  int cash;

  final List<RecentOperationModel> operations = [];
}
