import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { customer, staff, manager }

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.role,
    this.email,
    this.phone,
  });

  final String uid;
  final String name;
  final UserRole role;
  final String? email;
  final String? phone;

  @override
  List<Object?> get props => [uid, name, role, email, phone];
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits on sign-in, sign-out and token refresh (so role changes are picked up).
  Stream<AppUser?> get userChanges => _auth.idTokenChanges().asyncMap(_toAppUser);

  Future<AppUser?> _toAppUser(User? user) async {
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    final claim = token.claims?['role'];
    final role = UserRole.values.firstWhere(
      (r) => r.name == claim,
      orElse: () => UserRole.customer,
    );
    return AppUser(
      uid: user.uid,
      name: user.displayName ?? '',
      role: role,
      email: user.email,
      phone: user.phoneNumber,
    );
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _ensureProfile(cred.user!, name.trim());
    await cred.user!.reload();
  }

  Future<void> verifyPhone({
    required String phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      // Android may auto-read the SMS and sign the user in without typing the code.
      verificationCompleted: (credential) async {
        final result = await _auth.signInWithCredential(credential);
        await _ensureProfile(result.user!, '');
      },
      verificationFailed: (e) => onError(e.message ?? 'Phone verification failed'),
      codeSent: (id, _) => onCodeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmOtp(String verificationId, String code) async {
    final result = await _auth.signInWithCredential(
      PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code.trim()),
    );
    await _ensureProfile(result.user!, '');
  }

  /// Creates users/{uid} once. loyaltyPoints must start at 0 (enforced by security rules).
  Future<void> _ensureProfile(User user, String name) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'name': name,
      'email': user.email,
      'phone': user.phoneNumber,
      'loyaltyPoints': 0,
      'favoriteItemIds': <String>[],
      'fcmTokens': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();
}
