class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.customerId,
    required this.serverOutstanding,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final int serverOutstanding;
  final DateTime createdAt;
}
