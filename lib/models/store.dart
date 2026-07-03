import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? managerId;
  final String? managerName;
  final DateTime? createdAt;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.managerId,
    this.managerName,
    this.createdAt,
  });

  factory Store.fromMap(String id, Map<String, dynamic> map) {
    return Store(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'],
      managerId: map['managerId'],
      managerName: map['managerName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'managerId': managerId,
      'managerName': managerName,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}
