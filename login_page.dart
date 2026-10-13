import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_cubit.dart';
import '../data/auth_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LoginCubit>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<LoginCubit, LoginState>(
                builder: (context, s) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.restaurant, size: 56, color: scheme.primary),
                      const SizedBox(height: 12),
                      Text('Addis Delight',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Order food and book a table',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      SegmentedButton<LoginMode>(
                        segments: const [
                          ButtonSegment(
                              value: LoginMode.email,
                              label: Text('Email'),
                              icon: Icon(Icons.email_outlined)),
                          ButtonSegment(
                              value: LoginMode.phone,
                              label: Text('Phone'),
                              icon: Icon(Icons.phone_outlined)),
                        ],
                        selected: {s.mode},
                        onSelectionChanged: (v) => cubit.setMode(v.first),
                      ),
                      const SizedBox(height: 20),
                      if (s.mode == LoginMode.email) ..._emailForm(cubit, s),
                      if (s.mode == LoginMode.phone) ..._phoneForm(cubit, s),
                      if (s.error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(s.error!, style: TextStyle(color: scheme.error)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailForm(LoginCubit cubit, LoginState s) {
    return [
      if (s.isSignUp) ...[
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
      ],
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: s.loading
            ? null
            : () => cubit.submitEmail(
                  name: _name.text,
                  email: _email.text,
                  password: _password.text,
                ),
        child: _label(s, s.isSignUp ? 'Create account' : 'Sign in'),
      ),
      TextButton(
        onPressed: cubit.toggleSignUp,
        child: Text(s.isSignUp ? 'I already have an account' : 'New here? Create an account'),
      ),
    ];
  }

  List<Widget> _phoneForm(LoginCubit cubit, LoginState s) {
    if (s.verificationId == null) {
      return [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            hintText: '0911 234 567',
            prefixText: '+251  ',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: s.loading ? null : () => cubit.sendCode(_phone.text),
          child: _label(s, 'Send code'),
        ),
      ];
    }
    return [
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        decoration: const InputDecoration(labelText: '6-digit code'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: s.loading ? null : () => cubit.verifyCode(_code.text),
        child: _label(s, 'Verify and continue'),
      ),
      TextButton(
        onPressed: () => cubit.setMode(LoginMode.phone),
        child: const Text('Use a different number'),
      ),
    ];
  }

  Widget _label(LoginState s, String text) => s.loading
      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
      : Text(text);
}
