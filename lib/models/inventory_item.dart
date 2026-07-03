import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCategory { cctv, networking, security, accessories }

ItemCategory categoryFromString(String value) {
  return ItemCategory.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ItemCategory.accessories,
  );
}

extension ItemCategoryLabel on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.cctv:
        return 'CCTV & Cameras';
      case ItemCategory.networking:
        return 'Networking';
      case ItemCategory.security:
        return 'Security Systems';
      case ItemCategory.accessories:
        return 'Accessories';
    }
  }
}

class InventoryItem {
  final String id;
  final String storeId;
  final String name;
  final String sku;
  final ItemCategory category;
  final String? brand;
  final int quantity;
  final int minThreshold;
  final double unitPrice;
  final String? imageUrl;
  final String? description;
  final DateTime? updatedAt;
  final String? updatedByName;

  const InventoryItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.minThreshold,
    required this.unitPrice,
    this.brand,
    this.imageUrl,
    this.description,
    this.updatedAt,
    this.updatedByName,
  });

  bool get isLowStock => quantity <= minThreshold;
  bool get isOutOfStock => quantity <= 0;

  factory InventoryItem.fromMap(String id, String storeId, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      storeId: storeId,
      name: map['name'] ?? '',
      sku: map['sku'] ?? '',
      category: categoryFromString(map['category'] ?? 'accessories'),
      brand: map['brand'],
      quantity: (map['quantity'] ?? 0) as int,
      minThreshold: (map['minThreshold'] ?? 3) as int,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
      description: map['description'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedByName: map['updatedByName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'category': category.name,
      'brand': brand,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedByName': updatedByName,
    };
  }
}
