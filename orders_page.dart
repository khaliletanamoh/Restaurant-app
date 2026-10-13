import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../auth/bloc/auth_bloc.dart';
import '../cart/cart_bloc.dart';
import '../menu/menu_cubit.dart';
import 'order_models.dart';
import 'order_repository.dart';

/// Adds the still-available dishes of a past order to the cart at today's prices.
void reorder(BuildContext context, AppOrder order) {
  final menuItems = {for (final i in context.read<MenuCubit>().state.items) i.id: i};
  final cart = context.read<CartBloc>();
  var added = 0;
  var skipped = 0;
  for (final line in order.lines) {
    final item = menuItems[line.itemId];
    if (item != null && item.isAvailable) {
      cart.add(CartItemAdded(item, qty: line.qty));
      added++;
    } else {
      skipped++;
    }
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(skipped == 0
        ? 'Added $added dishes to your cart'
        : 'Added $added dishes. $skipped no longer available.'),
  ));
  if (added > 0) context.push('/cart');
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final Stream<List<AppOrder>> _stream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthBloc>().state.user!.uid;
    _stream = context.read<OrderRepository>().watchMyOrders(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: StreamBuilder<List<AppOrder>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load your orders'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = snap.data!;
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => context.go('/orders/${o.id}'),
                  title: Text('#${shortId(o.id)} \u00b7 ${o.type.label}'),
                  subtitle: Text(
                    '${formatDateTime(o.createdAt)}\n${o.lines.map((l) => '${l.qty}\u00d7 ${l.name}').join(', ')}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(etb(o.total)),
                      Text(o.status.label, style: Theme.of(context).textTheme.labelSmall),
                      Expanded(
                        child: IconButton(
                          tooltip: 'Reorder',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => reorder(context, o),
                          icon: const Icon(Icons.replay),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
