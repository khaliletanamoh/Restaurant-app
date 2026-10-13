import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import 'order_models.dart';
import 'order_repository.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late final Stream<AppOrder?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<OrderRepository>().watchOrder(widget.orderId);
  }

  List<OrderStatus> _steps(OrderType type) => [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.ready,
        if (type == OrderType.delivery) OrderStatus.outForDelivery,
        OrderStatus.completed,
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${shortId(widget.orderId)}')),
      body: StreamBuilder<AppOrder?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load this order'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final order = snap.data;
          if (order == null) return const Center(child: Text('Order not found'));

          final steps = _steps(order.type);
          final currentIndex = steps.indexOf(order.status);
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (order.status == OrderStatus.cancelled)
                Card(
                  color: scheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: const Text('This order was cancelled'),
                    subtitle: order.cancelReason == null ? null : Text(order.cancelReason!),
                  ),
                )
              else
                for (var i = 0; i < steps.length; i++)
                  _Step(
                    status: steps[i],
                    done: i < currentIndex,
                    current: i == currentIndex,
                    isLast: i == steps.length - 1,
                  ),
              const Divider(height: 32),
              Text(order.type.label, style: Theme.of(context).textTheme.titleMedium),
              if (order.address != null && order.address!.isNotEmpty) Text(order.address!),
              const SizedBox(height: 12),
              for (final l in order.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('${l.qty}\u00d7 ${l.name}'), Text(etb(l.unitPrice * l.qty))],
                  ),
                ),
              const Divider(height: 24),
              if (order.deliveryFee > 0) _row('Delivery fee', etb(order.deliveryFee)),
              _row('Total (cash)', etb(order.total), bold: true),
              if (order.pointsEarned > 0) _row('Points earned', '+${order.pointsEarned}'),
              const SizedBox(height: 24),
              if (order.status == OrderStatus.pending)
                OutlinedButton(
                  onPressed: () => context
                      .read<OrderRepository>()
                      .updateStatus(order.id, OrderStatus.cancelled),
                  child: const Text('Cancel order'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a, style: style), Text(b, style: style)],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final OrderStatus status;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = done || current;
    final color = active ? scheme.primary : scheme.outline;
    return Semantics(
      label: '${status.label}, ${done ? 'done' : current ? 'current step' : 'not yet'}',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Icon(done ? Icons.check_circle : status.iconData, color: color),
                if (!isLast) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                status.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: current ? FontWeight.bold : FontWeight.normal,
                      color: active ? null : scheme.outline,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
