enum GoldItemStatus { available, reserved, sold, inWorkshop, inTransit }

extension GoldItemStatusExtension on GoldItemStatus {
  String get displayName {
    switch (this) {
      case GoldItemStatus.available:
        return 'متاحة للبيع';
      case GoldItemStatus.reserved:
        return 'محجوزة';
      case GoldItemStatus.sold:
        return 'مباعة';
      case GoldItemStatus.inWorkshop:
        return 'في الورشة';
      case GoldItemStatus.inTransit:
        return 'قيد النقل';
    }
  }

  String get unavailableMessage {
    switch (this) {
      case GoldItemStatus.available:
        return '';
      case GoldItemStatus.reserved:
        return 'لا يمكن بيع قطعة محجوزة.';
      case GoldItemStatus.sold:
        return 'هذه القطعة تم بيعها بالفعل.';
      case GoldItemStatus.inWorkshop:
        return 'هذه القطعة مازالت في الورشة.';
      case GoldItemStatus.inTransit:
        return 'لا يمكن بيع قطعة قيد النقل.';
    }
  }
}
