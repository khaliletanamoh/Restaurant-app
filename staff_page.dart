import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/data/auth_repository.dart';
import '../orders/order_models.dart';
import '../orders/order_repository.dart';
import '../reservations/reservation_models.dart';
import '../reservations/reservation_repository.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthBloc>().state.user!.role;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff'),
          actions: [
            if (role == UserRole.manager)
              IconButton(
                tooltip: 'Dashboard',
                onPressed: () => context.go('/manager'),
                icon: const Icon(Icons.insights),
              ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Orders'), Tab(text: 'Reservations')]),
        ),
        body: const TabBarView(children: [_OrdersTab(), _ReservationsTab()]),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  late final Stream<List<AppOrder>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<OrderRepository>().watchActiveOrders();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();
    return StreamBuilder<List<AppOrder>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Could not load orders'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) return const Center(child: Text('No active orders'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            final next = o.status.next(o.type);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('#${shortId(o.id)} \u00b7 ${o.type.label}',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Chip(
                          avatar: Icon(o.status.iconData, size: 18),
                          label: Text(o.status.label),
                        ),
                      ],
                    ),
                    SelectableText('${o.customerName} \u00b7 ${o.customerPhone}'),
                    Text(formatDateTime(o.createdAt)),
                    const SizedBox(height: 8),
                    for (final l in o.lines)
                      Text('${l.qty}\u00d7 ${l.name}${l.note.isEmpty ? '' : '  (${l.note})'}'),
                    if (o.address != null && o.address!.isNotEmpty) Text('Address: ${o.address}'),
                    if (o.notes != null && o.notes!.isNotEmpty) Text('Notes: ${o.notes}'),
                    const SizedBox(height: 4),
                    Text('Total (cash): ${etb(o.total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (o.status == OrderStatus.pending) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => repo.updateStatus(o.id, OrderStatus.cancelled),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (next != null)
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () => repo.updateStatus(o.id, next),
                              child: Text(o.status.actionLabel),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReservationsTab extends StatefulWidget {
  const _ReservationsTab();

  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab> {
  late final Stream<List<Reservation>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ReservationRepository>().watchUpcoming();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReservationRepository>();
    return StreamBuilder<List<Reservation>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Could not load reservations'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('No upcoming reservations'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(formatDateTime(r.startsAt),
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Chip(label: Text(r.status.label)),
                      ],
                    ),
                    Text('${r.partySize} guests \u00b7 ${r.occasion}'),
                    SelectableText('${r.customerName} \u00b7 ${r.phone}'),
                    if (r.notes != null) Text('Notes: ${r.notes}'),
                    const SizedBox(height: 12),
                    if (r.status == ReservationStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => repo.updateStatus(r.id, ReservationStatus.declined),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () => repo.updateStatus(r.id, ReservationStatus.confirmed),
                              child: const Text('Confirm'),
                            ),
                          ),
                        ],
                      )
                    else
                      FilledButton.tonal(
                        onPressed: () => repo.updateStatus(r.id, ReservationStatus.completed),
                        child: const Text('Mark completed'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
