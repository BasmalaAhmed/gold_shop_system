abstract interface class GoldSalePriceRepo {
  Future<int> getSalePricePerGramPiasters(int karat);
  Future<int> getBuyPricePerGramPiasters(int karat);
}