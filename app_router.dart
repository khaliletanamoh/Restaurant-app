import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/cart/cart_page.dart';
import '../../features/manager/dashboard_page.dart';
import '../../features/menu/menu_page.dart';
import '../../features/orders/order_tracking_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/reservations/reservations_page.dart';
import '../../features/staff/staff_page.dart';
import 'customer_shell.dart';

/// Re-runs the router redirect whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

String _homeFor(UserRole role) => switch (role) {
      UserRole.customer => '/menu',
      UserRole.staff => '/staff',
      UserRole.manager => '/manager',
    };

GoRouter buildRouter(AuthBloc auth) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/splash',
    refreshListenable: _StreamListenable(auth.stream),
    redirect: (context, state) {
      final s = auth.state;
      final loc = state.matchedLocation;

      if (s.status == AuthStatus.unknown) return loc == '/splash' ? null : '/splash';
      if (s.status == AuthStatus.unauthenticated) return loc == '/login' ? null : '/login';

      final role = s.user!.role;
      if (loc == '/login' || loc == '/splash') return _homeFor(role);
      if (loc.startsWith('/staff') && role == UserRole.customer) return _homeFor(role);
      if (loc.startsWith('/manager') && role != UserRole.manager) return _homeFor(role);
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _Splash()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
      GoRoute(path: '/staff', builder: (_, __) => const StaffPage()),
      GoRoute(path: '/manager', builder: (_, __) => const DashboardPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/menu', builder: (_, __) => const MenuPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reservations',
              builder: (_, __) => const ReservationsPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: rootKey, // hides the bottom bar on the form
                  builder: (_, __) => const ReservationFormPage(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (_, __) => const OrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => OrderTrackingPage(orderId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
