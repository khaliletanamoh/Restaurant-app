import 'package:cloud_firestore/cloud_firestore.dart';

import 'reservation_models.dart';

class ReservationRepository {
  ReservationRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reservations');

  Future<void> create({
    required String userId,
    required String customerName,
    required String phone,
    required DateTime startsAt,
    required int partySize,
    required String occasion,
    String? notes,
  }) {
    return _col.add({
      'userId': userId,
      'customerName': customerName,
      'phone': phone,
      'startsAt': Timestamp.fromDate(startsAt),
      'partySize': partySize,
      'occasion': occasion,
      'notes': notes,
      'status': ReservationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Needs composite index: reservations(userId asc, startsAt desc).
  Stream<List<Reservation>> watchMine(String uid) => _col
      .where('userId', isEqualTo: uid)
      .orderBy('startsAt', descending: true)
      .limit(30)
      .snapshots()
      .map((s) => s.docs.map(Reservation.fromDoc).toList());

  /// Staff view. Needs composite index: reservations(status asc, startsAt asc).
  Stream<List<Reservation>> watchUpcoming() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _col
        .where('status', whereIn: [
          ReservationStatus.pending.name,
          ReservationStatus.confirmed.name,
        ])
        .where('startsAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('startsAt')
        .snapshots()
        .map((s) => s.docs.map(Reservation.fromDoc).toList());
  }

  Future<void> updateStatus(String id, ReservationStatus status) => _col.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
