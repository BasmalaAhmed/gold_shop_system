class GoldSaleFailure implements Exception {
  const GoldSaleFailure(this.message);

  final String message;

  @override
  String toString() => message;
}