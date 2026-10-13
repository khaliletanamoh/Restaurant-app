import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import '../auth/data/auth_repository.dart';
import '../orders/order_models.dart';
import '../orders/order_repository.dart';
import 'cart_bloc.dart';

class CheckoutState extends Equatable {
  const CheckoutState({this.submitting = false, this.orderId, this.queuedOffline = false, this.error});

  final bool submitting;
  final String? orderId;
  final bool queuedOffline;
  final String? error;

  @override
  List<Object?> get props => [submitting, orderId, queuedOffline, error];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._orders) : super(const CheckoutState());

  final OrderRepository _orders;

  Future<void> placeOrder({
    required AppUser user,
    required OrderType type,
    required List<CartLine> lines,
    required String phone,
    String? address,
    String? notes,
  }) async {
    if (lines.isEmpty) return;
    final normalized = normalizeEthiopianPhone(phone);
    if (normalized == null) {
      emit(const CheckoutState(error: 'Enter a valid Ethiopian mobile number'));
      return;
    }
    if (type == OrderType.delivery && (address == null || address.trim().isEmpty)) {
      emit(const CheckoutState(error: 'Please enter a delivery address'));
      return;
    }

    emit(const CheckoutState(submitting: true));
    final orderId = _orders.newOrderId();
    try {
      await _orders
          .placeOrder(
            orderId: orderId,
            user: user,
            type: type,
            lines: lines,
            phone: normalized,
            address: address?.trim(),
            notes: notes?.trim(),
          )
          .timeout(const Duration(seconds: 12));
      emit(CheckoutState(orderId: orderId));
    } on TimeoutException {
      // Firestore keeps the write in its local queue and sends it when the network returns.
      emit(CheckoutState(orderId: orderId, queuedOffline: true));
    } catch (_) {
      emit(const CheckoutState(error: 'Could not place the order. Please try again.'));
    }
  }
}
