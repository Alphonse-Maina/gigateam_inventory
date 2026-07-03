import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { stockRequest, requestApproved, requestRejected, lowStock, general }

NotificationType notifTypeFromString(String value) {
  return NotificationType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => NotificationType.general,
  );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId; // e.g. requestId or itemId
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: notifTypeFromString(map['type'] ?? 'general'),
      relatedId: map['relatedId'],
      read: map['read'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'relatedId': relatedId,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
