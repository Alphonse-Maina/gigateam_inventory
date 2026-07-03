import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, approved, rejected, fulfilled }

RequestStatus statusFromString(String value) {
  return RequestStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => RequestStatus.pending,
  );
}

class StockRequest {
  final String id;
  final String itemId;
  final String itemName;
  final String fromStoreId; // store being asked to send stock
  final String fromStoreName;
  final String toStoreId; // store that will receive stock
  final String toStoreName;
  final int quantityRequested;
  final String requestedById;
  final String requestedByName;
  final RequestStatus status;
  final String? respondedByName;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final String? note;

  const StockRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.fromStoreId,
    required this.fromStoreName,
    required this.toStoreId,
    required this.toStoreName,
    required this.quantityRequested,
    required this.requestedById,
    required this.requestedByName,
    required this.status,
    this.respondedByName,
    this.createdAt,
    this.respondedAt,
    this.note,
  });

  factory StockRequest.fromMap(String id, Map<String, dynamic> map) {
    return StockRequest(
      id: id,
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      fromStoreId: map['fromStoreId'] ?? '',
      fromStoreName: map['fromStoreName'] ?? '',
      toStoreId: map['toStoreId'] ?? '',
      toStoreName: map['toStoreName'] ?? '',
      quantityRequested: (map['quantityRequested'] ?? 0) as int,
      requestedById: map['requestedById'] ?? '',
      requestedByName: map['requestedByName'] ?? '',
      status: statusFromString(map['status'] ?? 'pending'),
      respondedByName: map['respondedByName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'fromStoreId': fromStoreId,
      'fromStoreName': fromStoreName,
      'toStoreId': toStoreId,
      'toStoreName': toStoreName,
      'quantityRequested': quantityRequested,
      'requestedById': requestedById,
      'requestedByName': requestedByName,
      'status': status.name,
      'respondedByName': respondedByName,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'respondedAt': respondedAt == null ? null : Timestamp.fromDate(respondedAt!),
      'note': note,
    };
  }
}
