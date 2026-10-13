import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../auth/bloc/auth_bloc.dart';
import '../auth/data/auth_repository.dart';
import 'user_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<UserProfile> _profile;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthBloc>().state.user!.uid;
    _profile = context.read<UserRepository>().watchProfile(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<UserProfile>(
            stream: _profile,
            builder: (context, snap) {
              final p = snap.data;
              return Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.name.isNotEmpty == true ? p!.name : 'Welcome',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email ?? user.phone ?? ''),
                      const SizedBox(height: 16),
                      Semantics(
                        label: '${p?.loyaltyPoints ?? 0} reward points',
                        child: Text('${p?.loyaltyPoints ?? 0} points',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      const Text('Earn 1 point for every 10 ETB on completed orders.'),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (user.role != UserRole.customer)
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Staff orders'),
              onTap: () => context.go('/staff'),
            ),
          if (user.role == UserRole.manager)
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Manager dashboard'),
              onTap: () => context.go('/manager'),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
    );
  }
}
