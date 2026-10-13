import 'package:addis_delight/features/cart/cart_bloc.dart';
import 'package:addis_delight/features/menu/menu_models.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

const _kitfo = MenuItem(
  id: 'kitfo',
  name: 'Kitfo',
  description: 'Minced beef',
  priceEtb: 500,
  categoryId: 'main',
);

void main() {
  group('CartBloc', () {
    blocTest<CartBloc, CartState>(
      'adds an item and merges the quantity when added twice',
      build: CartBloc.new,
      act: (bloc) => bloc
        ..add(const CartItemAdded(_kitfo))
        ..add(const CartItemAdded(_kitfo)),
      expect: () => [
        isA<CartState>().having((s) => s.count, 'count', 1),
        isA<CartState>()
            .having((s) => s.count, 'count', 2)
            .having((s) => s.subtotal, 'subtotal', 1000),
      ],
    );

    blocTest<CartBloc, CartState>(
      'decrementing the last unit removes the line',
      build: CartBloc.new,
      act: (bloc) => bloc
        ..add(const CartItemAdded(_kitfo))
        ..add(const CartItemDecremented('kitfo')),
      expect: () => [
        isA<CartState>().having((s) => s.count, 'count', 1),
        isA<CartState>().having((s) => s.isEmpty, 'isEmpty', true),
      ],
    );
  });
}
