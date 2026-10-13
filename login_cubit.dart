import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/formatters.dart';
import '../data/auth_repository.dart';

enum LoginMode { email, phone }

class LoginState extends Equatable {
  const LoginState({
    this.mode = LoginMode.email,
    this.isSignUp = false,
    this.loading = false,
    this.error,
    this.verificationId,
  });

  final LoginMode mode;
  final bool isSignUp;
  final bool loading;
  final String? error;
  final String? verificationId;

  LoginState copyWith({
    LoginMode? mode,
    bool? isSignUp,
    bool? loading,
    String? error,
    String? verificationId,
    bool clearError = false,
    bool clearVerification = false,
  }) {
    return LoginState(
      mode: mode ?? this.mode,
      isSignUp: isSignUp ?? this.isSignUp,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      verificationId: clearVerification ? null : (verificationId ?? this.verificationId),
    );
  }

  @override
  List<Object?> get props => [mode, isSignUp, loading, error, verificationId];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._auth) : super(const LoginState());

  final AuthRepository _auth;

  void setMode(LoginMode mode) =>
      emit(state.copyWith(mode: mode, clearError: true, clearVerification: true));

  void toggleSignUp() => emit(state.copyWith(isSignUp: !state.isSignUp, clearError: true));

  Future<void> submitEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.length < 6) {
      emit(state.copyWith(error: 'Enter your email and a password of at least 6 characters'));
      return;
    }
    if (state.isSignUp && name.trim().isEmpty) {
      emit(state.copyWith(error: 'Please enter your name'));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    try {
      if (state.isSignUp) {
        await _auth.signUpWithEmail(name: name, email: email, password: password);
      } else {
        await _auth.signInWithEmail(email, password);
      }
      emit(state.copyWith(loading: false));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(loading: false, error: e.message ?? 'Authentication failed'));
    }
  }

  Future<void> sendCode(String rawPhone) async {
    final phone = normalizeEthiopianPhone(rawPhone);
    if (phone == null) {
      emit(state.copyWith(error: 'Enter a valid Ethiopian mobile number, e.g. 0911 234 567'));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await _auth.verifyPhone(
        phone: phone,
        onCodeSent: (id) {
          if (!isClosed) emit(state.copyWith(loading: false, verificationId: id));
        },
        onError: (message) {
          if (!isClosed) emit(state.copyWith(loading: false, error: message));
        },
      );
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(loading: false, error: e.message ?? 'Could not send the code'));
    }
  }

  Future<void> verifyCode(String code) async {
    final id = state.verificationId;
    if (id == null || code.trim().length != 6) {
      emit(state.copyWith(error: 'Enter the 6-digit code'));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await _auth.confirmOtp(id, code);
      emit(state.copyWith(loading: false));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(loading: false, error: e.message ?? 'Wrong code, please try again'));
    }
  }
}
