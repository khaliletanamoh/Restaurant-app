import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReservationStatus { pending, confirmed, declined, cancelled, completed }

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
        ReservationStatus.pending => 'Pending',
        ReservationStatus.confirmed => 'Confirmed',
        ReservationStatus.declined => 'Declined',
        ReservationStatus.cancelled => 'Cancelled',
        ReservationStatus.completed => 'Completed',
      };
}

class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.startsAt,
    required this.partySize,
    required this.occasion,
    required this.status,
    this.notes,
  });

  final String id;
  final String userId;
  final String customerName;
  final String phone;
  final DateTime startsAt;
  final int partySize;
  final String occasion;
  final ReservationStatus status;
  final String? notes;

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Reservation(
      id: doc.id,
      userId: m['userId'] as String? ?? '',
      customerName: m['customerName'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      startsAt: (m['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      partySize: (m['partySize'] as num?)?.toInt() ?? 1,
      occasion: m['occasion'] as String? ?? 'Regular visit',
      status: ReservationStatus.values
          .firstWhere((s) => s.name == m['status'], orElse: () => ReservationStatus.pending),
      notes: m['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, startsAt, partySize];
}
