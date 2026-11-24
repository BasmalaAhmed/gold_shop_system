import 'package:gold_shop_app/modules/shop_monitoring/features/branch_monitoring/domain/entities/branch.dart';

class BranchModel {
  final String id;
  final String name;
  
  const BranchModel({required this.id, required this.name});

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  Branch toEntity() {
    return Branch(id: id, name: name);
  }
}
