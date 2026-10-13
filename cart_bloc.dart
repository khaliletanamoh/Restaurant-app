import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../menu/menu_models.dart';

class CartLine extends Equatable {
  const CartLine({required this.item, required this.qty});

  final MenuItem item;
  final int qty;

  int get total => item.priceEtb * qty;

  @override
  List<Object?> get props => [item, qty];
}

class CartState extends Equatable {
  const CartState([this.lines = const []]);

  final List<CartLine> lines;

  int get subtotal => lines.fold(0, (sum, l) => sum + l.total);
  int get count => lines.fold(0, (sum, l) => sum + l.qty);
  bool get isEmpty => lines.isEmpty;

  @override
  List<Object?> get props => [lines];
}

sealed class CartEvent {
  const CartEvent();
}

class CartItemAdded extends CartEvent {
  const CartItemAdded(this.item, {this.qty = 1});
  final MenuItem item;
  final int qty;
}

class CartItemDecremented extends CartEvent {
  const CartItemDecremented(this.itemId);
  final String itemId;
}

class CartLineRemoved extends CartEvent {
  const CartLineRemoved(this.itemId);
  final String itemId;
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>((e, emit) {
      final lines = [...state.lines];
      final i = lines.indexWhere((l) => l.item.id == e.item.id);
      if (i == -1) {
        lines.add(CartLine(item: e.item, qty: e.qty));
      } else {
        lines[i] = CartLine(item: e.item, qty: lines[i].qty + e.qty);
      }
      emit(CartState(lines));
    });

    on<CartItemDecremented>((e, emit) {
      final lines = <CartLine>[];
      for (final l in state.lines) {
        if (l.item.id != e.itemId) {
          lines.add(l);
        } else if (l.qty > 1) {
          lines.add(CartLine(item: l.item, qty: l.qty - 1));
        }
      }
      emit(CartState(lines));
    });

    on<CartLineRemoved>((e, emit) =>
        emit(CartState(state.lines.where((l) => l.item.id != e.itemId).toList())));

    on<CartCleared>((e, emit) => emit(const CartState()));
  }
}
