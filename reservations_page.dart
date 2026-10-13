import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../auth/bloc/auth_bloc.dart';
import 'reservation_cubit.dart';
import 'reservation_models.dart';
import 'reservation_repository.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  late final Stream<List<Reservation>> _stream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthBloc>().state.user!.uid;
    _stream = context.read<ReservationRepository>().watchMine(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Table reservations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reservations/new'),
        icon: const Icon(Icons.event_seat),
        label: const Text('Book a table'),
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load reservations'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('No reservations yet'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(formatDateTime(r.startsAt)),
                  subtitle: Text('${r.partySize} guests \u00b7 ${r.occasion}'),
                  trailing: Chip(label: Text(r.status.label)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReservationFormPage extends StatelessWidget {
  const ReservationFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationCubit(context.read<ReservationRepository>()),
      child: const _FormView(),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView();

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  static const _occasions = [
    'Regular visit',
    'Birthday',
    'Business lunch',
    'Family gathering',
    'Special event',
  ];

  late final TextEditingController _phone;
  final _notes = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _party = 2;
  String _occasion = _occasions.first;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: context.read<AuthBloc>().state.user?.phone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime? get _startsAt => (_date == null || _time == null)
      ? null
      : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReservationCubit, ReservationFormState>(
      listener: (context, s) {
        if (s.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.error!)));
        }
        if (s.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Request sent. We will confirm shortly.'),
          ));
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Book a table')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_date == null
                        ? 'Date'
                        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time == null ? 'Time' : _time!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Text('Guests')),
                IconButton(
                  tooltip: 'Fewer guests',
                  onPressed: _party > 1 ? () => setState(() => _party--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_party', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: 'More guests',
                  onPressed: _party < ReservationCubit.maxPartySize
                      ? () => setState(() => _party++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _occasion,
              decoration: const InputDecoration(labelText: 'Occasion'),
              items: [for (final o in _occasions) DropdownMenuItem(value: o, child: Text(o))],
              onChanged: (v) => setState(() => _occasion = v ?? _occasion),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 24),
            BlocBuilder<ReservationCubit, ReservationFormState>(
              builder: (context, s) => FilledButton(
                onPressed: s.submitting
                    ? null
                    : () => context.read<ReservationCubit>().submit(
                          user: context.read<AuthBloc>().state.user!,
                          startsAt: _startsAt,
                          partySize: _party,
                          phone: _phone.text,
                          occasion: _occasion,
                          notes: _notes.text,
                        ),
                child: s.submitting
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Request table'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
