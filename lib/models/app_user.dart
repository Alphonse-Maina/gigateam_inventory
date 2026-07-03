import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, manager, staff }

UserRole roleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    default:
      return UserRole.staff;
  }
}

String roleToString(UserRole role) => role.name;

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  // Null for admins (they aren't tied to a single store).
  final String? storeId;
  final String? photoUrl;
  final bool active;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.storeId,
    this.photoUrl,
    this.active = true,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager;
  bool get isStaff => role == UserRole.staff;

  /// Whether this user may create/edit/delete items belonging to [targetStoreId].
  bool canEditStore(String targetStoreId) {
    if (isAdmin) return true;
    if (isManager) return storeId == targetStoreId;
    return false; // staff never edit
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: roleFromString(map['role'] ?? 'staff'),
      storeId: map['storeId'],
      photoUrl: map['photoUrl'],
      active: map['active'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': roleToString(role),
      'storeId': storeId,
      'photoUrl': photoUrl,
      'active': active,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}
