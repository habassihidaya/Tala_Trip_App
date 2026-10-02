import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _mobileNumber.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      SignUpRequested(
        username: _username.text.trim(),
        email: _email.text.trim(),
        mobileNumber: _mobileNumber.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthVerificationRequired,
      listener: (context, state) {
      context.go('/sign-in');
         },
      builder: (context, state) {
        final loading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Create your TALA account')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a username'
                              : null,
                    ),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Enter a valid email'
                              : null,
                    ),
                    TextFormField(
                      controller: _mobileNumber,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a mobile number'
                              : null,
                    ),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.length < 6
                              ? 'Use at least 6 characters'
                              : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: Text(
                        loading ? 'Creating account...' : 'Sign up',
                      ),
                    ),
                    if (state is AuthError) ...[
                      const SizedBox(height: 16),
                      Text('Registration failed: ${state.message}'),
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