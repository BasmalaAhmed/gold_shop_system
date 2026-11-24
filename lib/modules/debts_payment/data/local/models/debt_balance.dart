class DebtBalance {
  const DebtBalance({
    required this.debtId,
    required this.serverOutstanding,
    required this.localOutstanding,
    required this.createdAt,
    this.dueDate,
    this.confirmedAmount = 0,
    this.pendingAmount = 0,
    this.conflictAmount = 0,
  });

  final String debtId;
  final int serverOutstanding;
  final int localOutstanding;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int confirmedAmount;
  final int pendingAmount;
  final int conflictAmount;
  int get serverConfirmedOutstanding => serverOutstanding - confirmedAmount;
}
