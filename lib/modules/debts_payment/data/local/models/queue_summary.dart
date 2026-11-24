class QueueSummary {
  const QueueSummary({this.open = 0, this.conflicts = 0, this.lastSyncedAt});

  static const empty = QueueSummary();
  final int open;
  final int conflicts;
  final DateTime? lastSyncedAt;
  int get badge => open + conflicts;
}
