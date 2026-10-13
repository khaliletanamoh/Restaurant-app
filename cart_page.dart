import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../auth/bloc/auth_bloc.dart';
import '../orders/order_models.dart';
import '../orders/order_repository.dart';
import 'cart_bloc.dart';
import 'checkout_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CheckoutCubit(context.read<OrderRepository>()),
      child: const _CartView(),
    );
  }
}

class _CartView extends StatefulWidget {
  const _CartView();

  @override
  State<_CartView> createState() => _CartViewState();
}

class _CartViewState extends State<_CartView> {
  late final TextEditingController _phone;
  final _address = TextEditingController();
  final _notes = TextEditingController();
  OrderType _type = OrderType.takeaway;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, s) {
        if (s.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
        }
        if (s.orderId != null) {
          context.read<CartBloc>().add(const CartCleared());
          if (s.queuedOffline) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("You're offline. Your order will be sent when you reconnect."),
            ));
          }
          context.go('/orders/${s.orderId}');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Your cart')),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            if (cart.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your cart is empty'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/menu'),
                      child: const Text('Browse the menu'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final line in cart.lines) _LineTile(line: line),
                const Divider(height: 32),
                SegmentedButton<OrderType>(
                  segments: [
                    for (final t in OrderType.values)
                      ButtonSegment(value: t, label: Text(t.label)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact phone'),
                ),
                if (_type == OrderType.delivery) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Delivery address',
                      hintText: 'Area, street, landmark, building',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 16),
                _row('Subtotal', etb(cart.subtotal)),
                if (_type == OrderType.delivery)
                  _row('Delivery fee', 'added when we confirm'),
                _row('Payment', 'Cash on ${_type == OrderType.delivery ? 'delivery' : 'pickup'}'),
              ],
            );
          },
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (context, cart) {
            if (cart.isEmpty) return const SizedBox.shrink();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BlocBuilder<CheckoutCubit, CheckoutState>(
                  builder: (context, checkout) => FilledButton(
                    onPressed: checkout.submitting
                        ? null
                        : () => context.read<CheckoutCubit>().placeOrder(
                              user: context.read<AuthBloc>().state.user!,
                              type: _type,
                              lines: cart.lines,
                              phone: _phone.text,
                              address: _address.text,
                              notes: _notes.text,
                            ),
                    child: checkout.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text('Place order \u00b7 ${etb(cart.subtotal)}'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(value)],
        ),
      );
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name, style: Theme.of(context).textTheme.titleSmall),
                Text(etb(line.total)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove one ${line.item.name}',
            onPressed: () => bloc.add(CartItemDecremented(line.item.id)),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('${line.qty}', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            tooltip: 'Add one ${line.item.name}',
            onPressed: () => bloc.add(CartItemAdded(line.item)),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
