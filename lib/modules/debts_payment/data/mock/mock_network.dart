import 'dart:async';

class MockNetwork {
  MockNetwork({bool initiallyOnline = true}) : _isOnline = initiallyOnline;

  bool _isOnline;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  bool get isOnline => _isOnline;
  Stream<bool> get changes => _changes.stream;

  void setOnline(bool isOnline) {
    if (_isOnline == isOnline) return;

    _isOnline = isOnline;
    _changes.add(isOnline);
  }

  Future<void> dispose() => _changes.close();
}

class MockNetworkUnavailable implements Exception {
  const MockNetworkUnavailable();

  @override
  String toString() => 'Mock network is unavailable.';
}
