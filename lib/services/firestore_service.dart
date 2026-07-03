import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';
import '../models/inventory_item.dart';
import '../models/stock_request.dart';
import '../models/activity_log.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // Stores
  // ---------------------------------------------------------------------
  Stream<List<Store>> watchStores() {
    return _db.collection('stores').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => Store.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<Store?> getStore(String storeId) async {
    final doc = await _db.collection('stores').doc(storeId).get();
    return doc.exists ? Store.fromMap(doc.id, doc.data()!) : null;
  }

  Future<void> createStore(Store store) {
    return _db.collection('stores').add(store.toMap());
  }

  Future<void> updateStore(Store store) {
    return _db.collection('stores').doc(store.id).update(store.toMap());
  }

  // ---------------------------------------------------------------------
  // Inventory items — stored as a subcollection per store so security
  // rules can cleanly scope writes to "your own store".
  // ---------------------------------------------------------------------
  Stream<List<InventoryItem>> watchItemsForStore(String storeId) {
    return _db
        .collection('stores')
        .doc(storeId)
        .collection('items')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => InventoryItem.fromMap(d.id, storeId, d.data())).toList());
  }

  /// Global search across every store (used by staff/managers/admin to see
  /// "who has what"). Firestore has no native cross-collection-group text
  /// search, so we query the `items` collection group and filter client
  /// side on [query] against name/sku — fine at shop-scale inventories.
  Stream<List<InventoryItem>> watchAllItems() {
    return _db.collectionGroup('items').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) {
            final storeId = d.reference.parent.parent!.id;
            return InventoryItem.fromMap(d.id, storeId, d.data());
          }).toList(),
        );
  }

  Future<void> addItem(String storeId, InventoryItem item, {required AppUser actor}) async {
    await _db.collection('stores').doc(storeId).collection('items').add(item.toMap());
    await logActivity(
      storeId: storeId,
      action: LogAction.added,
      itemName: item.name,
      quantityChange: item.quantity,
      actor: actor,
      details: 'SKU ${item.sku}',
    );
  }

  Future<void> updateItem(String storeId, InventoryItem item, {required AppUser actor, int? previousQty}) async {
    await _db.collection('stores').doc(storeId).collection('items').doc(item.id).update(item.toMap());
    final delta = previousQty == null ? null : item.quantity - previousQty;
    await logActivity(
      storeId: storeId,
      action: LogAction.edited,
      itemName: item.name,
      quantityChange: delta,
      actor: actor,
    );
  }

  Future<void> deleteItem(String storeId, InventoryItem item, {required AppUser actor}) async {
    await _db.collection('stores').doc(storeId).collection('items').doc(item.id).delete();
    await logActivity(
      storeId: storeId,
      action: LogAction.removed,
      itemName: item.name,
      quantityChange: -item.quantity,
      actor: actor,
    );
  }

  // ---------------------------------------------------------------------
  // Stock requests (inter-store transfer requests)
  // ---------------------------------------------------------------------
  Stream<List<StockRequest>> watchRequestsForStore(String storeId) {
    return _db
        .collection('requests')
        .where('fromStoreId', isEqualTo: storeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StockRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<StockRequest>> watchRequestsMadeBy(String uid) {
    return _db
        .collection('requests')
        .where('requestedById', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StockRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<StockRequest>> watchAllRequests() {
    return _db
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StockRequest.fromMap(d.id, d.data())).toList());
  }

  Future<void> createRequest(StockRequest request) async {
    await _db.collection('requests').add(request.toMap());
    // Notify the manager(s) of the store being asked for stock.
    await _notifyStore(
      storeId: request.fromStoreId,
      title: 'Stock request: ${request.itemName}',
      body: '${request.requestedByName} at ${request.toStoreName} requested '
          '${request.quantityRequested} x ${request.itemName}.',
      type: NotificationType.stockRequest,
      relatedId: request.id,
    );
  }

  Future<void> respondToRequest({
    required StockRequest request,
    required bool approve,
    required AppUser actor,
  }) async {
    final newStatus = approve ? RequestStatus.approved : RequestStatus.rejected;
    await _db.collection('requests').doc(request.id).update({
      'status': newStatus.name,
      'respondedByName': actor.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(
      storeId: request.fromStoreId,
      action: approve ? LogAction.requestApproved : LogAction.requestRejected,
      itemName: request.itemName,
      quantityChange: request.quantityRequested,
      actor: actor,
      details: 'Requested by ${request.requestedByName} for ${request.toStoreName}',
    );

    await _notifyUser(
      uid: request.requestedById,
      title: approve ? 'Request approved' : 'Request rejected',
      body: '${request.itemName} (${request.quantityRequested}) — '
          '${approve ? "approved" : "rejected"} by ${actor.name}.',
      type: approve ? NotificationType.requestApproved : NotificationType.requestRejected,
      relatedId: request.id,
    );
  }

  // ---------------------------------------------------------------------
  // Activity log — every mutation writes here. Only Admins read the full
  // collection (enforced by security rules); managers/staff never query it.
  // ---------------------------------------------------------------------
  Future<void> logActivity({
    required String storeId,
    required LogAction action,
    required String itemName,
    required AppUser actor,
    int? quantityChange,
    String? details,
  }) async {
    final store = await getStore(storeId);
    final log = ActivityLog(
      id: '',
      storeId: storeId,
      storeName: store?.name ?? storeId,
      action: action,
      itemName: itemName,
      quantityChange: quantityChange,
      performedById: actor.uid,
      performedByName: actor.name,
      details: details,
    );
    await _db.collection('logs').add(log.toMap());
  }

  Stream<List<ActivityLog>> watchAllLogs({int limit = 200}) {
    return _db
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ActivityLog.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------------
  // Notifications — per-user subcollection.
  // ---------------------------------------------------------------------
  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());
  }

  Future<void> markNotificationRead(String uid, String notifId) {
    return _db.collection('users').doc(uid).collection('notifications').doc(notifId).update({'read': true});
  }

  Future<void> _notifyUser({
    required String uid,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) {
    final notif = AppNotification(id: '', title: title, body: body, type: type, relatedId: relatedId);
    return _db.collection('users').doc(uid).collection('notifications').add(notif.toMap());
  }

  /// Notifies every manager (and admins) tied to a store — used when a
  /// stock request comes in, so whoever runs that store sees it immediately.
  Future<void> _notifyStore({
    required String storeId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    final recipients = await _db.collection('users').where('storeId', isEqualTo: storeId).get();
    final admins = await _db.collection('users').where('role', isEqualTo: 'admin').get();
    final batch = _db.batch();
    for (final doc in [...recipients.docs, ...admins.docs]) {
      final ref = doc.reference.collection('notifications').doc();
      batch.set(ref, AppNotification(id: '', title: title, body: body, type: type, relatedId: relatedId).toMap());
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------
  // Team (admin-only user management)
  // ---------------------------------------------------------------------
  Stream<List<AppUser>> watchTeam() {
    return _db.collection('users').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList(),
        );
  }
}
