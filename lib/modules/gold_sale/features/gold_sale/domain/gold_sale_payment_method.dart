enum GoldSalePaymentMethod { cash, card, bankTransfer, mobileWallet, other }

extension GoldSalePaymentMethodLabel on GoldSalePaymentMethod {
  String get arabicLabel => switch (this) {
    GoldSalePaymentMethod.cash => 'كاش',
    GoldSalePaymentMethod.card => 'كارت',
    GoldSalePaymentMethod.bankTransfer => 'تحويل',
    GoldSalePaymentMethod.mobileWallet => 'فودافون كاش',
    GoldSalePaymentMethod.other => 'إنستاباي',
  };
}
