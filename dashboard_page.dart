import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../orders/order_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final Stream<Map<String, dynamic>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = context.read<OrderRepository>().watchDailyStats(addisDateKey());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Staff orders',
            onPressed: () => context.go('/staff'),
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _stats,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load today\'s numbers'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final m = snap.data!;
          final orders = (m['orderCount'] as num?)?.toInt() ?? 0;
          final revenue = (m['revenue'] as num?)?.toInt() ?? 0;
          final average = orders == 0 ? 0 : (revenue / orders).round();

          final top = ((m['topItems'] as Map?) ?? const {})
              .values
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList()
            ..sort((a, b) => ((b['qty'] as num?) ?? 0).compareTo((a['qty'] as num?) ?? 0));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _Stat(label: 'Orders', value: '$orders')),
                  const SizedBox(width: 12),
                  Expanded(child: _Stat(label: 'Revenue', value: etb(revenue))),
                ],
              ),
              const SizedBox(height: 12),
              _Stat(label: 'Average order', value: etb(average)),
              const SizedBox(height: 24),
              Text('Top dishes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (top.isEmpty) const Text('No completed orders yet today'),
              for (final t in top.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${t['name']}'),
                  trailing: Text('${(t['qty'] as num?)?.toInt() ?? 0} sold'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Semantics(
              label: '$label $value',
              child: Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ),
          ],
        ),
      ),
    );
  }
}
