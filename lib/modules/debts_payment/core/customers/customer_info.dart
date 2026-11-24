class CustomerInfo {
  const CustomerInfo(this.name, this.phone);

  final String name;
  final String phone;

  String get firstName => name.split(' ').first;
}

const _directory = <String, CustomerInfo>{
  'customer-001': CustomerInfo('سعاد عبد الرحمن', '0100 123 4567'),
};

CustomerInfo customerInfoFor(String customerId) =>
    _directory[customerId] ?? CustomerInfo(customerId, '');