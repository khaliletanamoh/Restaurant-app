import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import '../auth/data/auth_repository.dart';
import 'reservation_repository.dart';

class ReservationFormState extends Equatable {
  const ReservationFormState({this.submitting = false, this.success = false, this.error});

  final bool submitting;
  final bool success;
  final String? error;

  @override
  List<Object?> get props => [submitting, success, error];
}

class ReservationCubit extends Cubit<ReservationFormState> {
  ReservationCubit(this._repo) : super(const ReservationFormState());

  final ReservationRepository _repo;

  // Assumption: open 08:00-22:00. Move to settings/restaurant when hours differ per day.
  static const openHour = 8;
  static const closeHour = 22;
  static const maxPartySize = 30;

  Future<void> submit({
    required AppUser user,
    required DateTime? startsAt,
    required int partySize,
    required String phone,
    required String occasion,
    String? notes,
  }) async {
    final normalized = normalizeEthiopianPhone(phone);
    if (startsAt == null) {
      emit(const ReservationFormState(error: 'Choose a date and time'));
    } else if (startsAt.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      emit(const ReservationFormState(error: 'Please book at least 1 hour ahead'));
    } else if (startsAt.hour < openHour || startsAt.hour >= closeHour) {
      emit(const ReservationFormState(error: 'We are open from 08:00 to 22:00'));
    } else if (partySize < 1 || partySize > maxPartySize) {
      emit(const ReservationFormState(error: 'Party size must be between 1 and 30'));
    } else if (normalized == null) {
      emit(const ReservationFormState(error: 'Enter a valid Ethiopian mobile number'));
    } else {
      emit(const ReservationFormState(submitting: true));
      try {
        await _repo.create(
          userId: user.uid,
          customerName: user.name,
          phone: normalized,
          startsAt: startsAt,
          partySize: partySize,
          occasion: occasion,
          notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        );
        emit(const ReservationFormState(success: true));
      } catch (_) {
        emit(const ReservationFormState(error: 'Could not send your request. Please try again.'));
      }
    }
  }
}
