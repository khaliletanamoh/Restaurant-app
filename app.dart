import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/cart/cart_bloc.dart';
import 'features/menu/menu_cubit.dart';
import 'features/menu/menu_repository.dart';
import 'features/orders/order_repository.dart';
import 'features/profile/user_repository.dart';
import 'features/reservations/reservation_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _auth = AuthRepository();
  late final _menu = MenuRepository();
  late final _orders = OrderRepository();
  late final _reservations = ReservationRepository();
  late final _users = UserRepository();
  late final _notifications = NotificationService(_users);

  late final _authBloc = AuthBloc(_auth)..add(const AuthStarted());
  late final _cartBloc = CartBloc();
  late final _menuCubit = MenuCubit(_menu);
  late final GoRouter _router = buildRouter(_authBloc);

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    _cartBloc.close();
    _menuCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _auth),
        RepositoryProvider.value(value: _menu),
        RepositoryProvider.value(value: _orders),
        RepositoryProvider.value(value: _reservations),
        RepositoryProvider.value(value: _users),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _cartBloc),
          BlocProvider.value(value: _menuCubit),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              _notifications.register(state.user!);
            } else if (state.status == AuthStatus.unauthenticated) {
              _notifications.unregister();
            }
          },
          child: MaterialApp.router(
            title: 'Addis Delight',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
