import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.loyaltyPoints,
    required this.favoriteItemIds,
  });

  final String name;
  final String phone;
  final int loyaltyPoints;
  final Set<String> favoriteItemIds;

  @override
  List<Object?> get props => [name, phone, loyaltyPoints, favoriteItemIds];
}

class UserRepository {
  UserRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('users').doc(uid);

  Stream<UserProfile> watchProfile(String uid) => _doc(uid).snapshots().map((d) {
        final m = d.data() ?? {};
        return UserProfile(
          name: m['name'] as String? ?? '',
          phone: m['phone'] as String? ?? '',
          loyaltyPoints: (m['loyaltyPoints'] as num?)?.toInt() ?? 0,
          favoriteItemIds: ((m['favoriteItemIds'] as List?) ?? const []).cast<String>().toSet(),
        );
      });

  Future<void> setFavorite(String uid, String itemId, {required bool value}) => _doc(uid).update({
        'favoriteItemIds':
            value ? FieldValue.arrayUnion([itemId]) : FieldValue.arrayRemove([itemId]),
      });

  Future<void> saveFcmToken(String uid, String token) => _doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
}
