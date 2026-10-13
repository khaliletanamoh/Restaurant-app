import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);
  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.authenticated(AppUser user) : this._(AuthStatus.authenticated, user);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}

sealed class AuthEvent {
  const AuthEvent();
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState.unknown()) {
    on<AuthStarted>((event, emit) {
      return emit.forEach<AppUser?>(
        _repo.userChanges,
        onData: (user) => user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
        onError: (_, __) => const AuthState.unauthenticated(),
      );
    });
    on<AuthSignOutRequested>((event, emit) => _repo.signOut());
  }

  final AuthRepository _repo;
}
