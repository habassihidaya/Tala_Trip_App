import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      SignInRequested(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }
  void _requestPasswordReset() {
  final email = _email.text.trim();

  if (email.isEmpty || !email.contains('@')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter your email address first.'),
      ),
    );
    return;
  }

  context.read<AuthBloc>().add(PasswordResetRequested(email));
}

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('TALA Trip')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null || !value.trim().contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Enter your password'
                              : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                        child: TextButton(
                         onPressed: loading ? null : _requestPasswordReset,
                         child: const Text('Forgot password?'),
                          ),
                          ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: Text(loading ? 'Signing in...' : 'Sign in'),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignUpPage(),
                                ),
                              ),
                      child: const Text('Create an account'),
                    ),
                    if (state is AuthError) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    
                    if (state is AuthPasswordResetEmailSent) ...[
                     const SizedBox(height: 12),
                    const Text(
                       'If an account uses this email, check your inbox for a password reset link.',
                         ),
                          ],

                    if (state is AuthVerificationRequired) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.message ??
                            'Please verify ${state.user.email} using the link we sent you.',
                      ),
                      TextButton(
                        onPressed: () => context.read<AuthBloc>().add(
                              ResendVerificationEmailRequested(),
                            ),
                        child: const Text('Resend verification email'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.read<AuthBloc>().add(
                              CheckEmailVerificationRequested(),
                            ),
                        child: const Text("I've verified my email"),
                      ),
                    ],
                    if (state is AuthAuthenticated) ...[
                      const SizedBox(height: 16),
                      Text('Signed in as ${state.user.username}.'),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}