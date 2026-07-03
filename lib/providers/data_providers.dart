import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';
import '../models/inventory_item.dart';
import '../models/stock_request.dart';
import '../models/activity_log.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final storesProvider = StreamProvider<List<Store>>((ref) {
  return ref.watch(firestoreServiceProvider).watchStores();
});

/// Items scoped to one store (used on the Store Detail screen).
final storeItemsProvider = StreamProvider.family<List<InventoryItem>, String>((ref, storeId) {
  return ref.watch(firestoreServiceProvider).watchItemsForStore(storeId);
});

/// Every item across every store — powers global search / "who has what".
final allItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllItems();
});

/// Requests aimed at the current user's store (manager inbox).
final incomingRequestsProvider = StreamProvider<List<StockRequest>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.storeId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchRequestsForStore(user.storeId!);
});

/// Requests the current user has personally made.
final myRequestsProvider = StreamProvider<List<StockRequest>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchRequestsMadeBy(user.uid);
});

/// Admin-only: every request in the system.
final allRequestsProvider = StreamProvider<List<StockRequest>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllRequests();
});

/// Admin-only: full audit trail.
final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllLogs();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchNotifications(user.uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.read).length;
});

final teamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(firestoreServiceProvider).watchTeam();
});
