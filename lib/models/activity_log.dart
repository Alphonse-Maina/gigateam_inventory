import 'package:cloud_firestore/cloud_firestore.dart';

enum LogAction { added, removed, edited, transferIn, transferOut, requestCreated, requestApproved, requestRejected }

LogAction logActionFromString(String value) {
  return LogAction.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LogAction.edited,
  );
}

extension LogActionLabel on LogAction {
  String get label {
    switch (this) {
      case LogAction.added:
        return 'Item added';
      case LogAction.removed:
        return 'Item removed';
      case LogAction.edited:
        return 'Item edited';
      case LogAction.transferIn:
        return 'Stock received';
      case LogAction.transferOut:
        return 'Stock sent';
      case LogAction.requestCreated:
        return 'Request created';
      case LogAction.requestApproved:
        return 'Request approved';
      case LogAction.requestRejected:
        return 'Request rejected';
    }
  }
}

class ActivityLog {
  final String id;
  final String storeId;
  final String storeName;
  final LogAction action;
  final String itemName;
  final int? quantityChange;
  final String performedById;
  final String performedByName;
  final DateTime? timestamp;
  final String? details;

  const ActivityLog({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.action,
    required this.itemName,
    required this.performedById,
    required this.performedByName,
    this.quantityChange,
    this.timestamp,
    this.details,
  });

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id: id,
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      action: logActionFromString(map['action'] ?? 'edited'),
      itemName: map['itemName'] ?? '',
      quantityChange: map['quantityChange'],
      performedById: map['performedById'] ?? '',
      performedByName: map['performedByName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'action': action.name,
      'itemName': itemName,
      'quantityChange': quantityChange,
      'performedById': performedById,
      'performedByName': performedByName,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details,
    };
  }
}
