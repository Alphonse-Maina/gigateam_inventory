import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Wraps FirebaseAuth + the `users` collection. Accounts are created by an
/// Admin from inside the app (Team screen) — there is no public sign-up flow,
/// since every account maps to a role and, for managers/staff, a store.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Stream<AppUser?> profileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromMap(uid, doc.data()!) : null,
        );
  }

  /// Admin-only: creates a Firebase Auth account + Firestore profile for a
  /// new manager/staff member. Requires a secondary (non-persisting) Auth
  /// instance in production to avoid signing the admin out — see README.
  Future<void> createTeamMember({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? storeId,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set(
          AppUser(
            uid: uid,
            name: name,
            email: email.trim(),
            role: role,
            storeId: storeId,
            phone: phone,
          ).toMap(),
        );
  }
}
