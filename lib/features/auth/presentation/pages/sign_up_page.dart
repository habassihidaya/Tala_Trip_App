import 'package:flutter/material.dart';
import 'package:tala_trip_app/features/auth/domain/usecases/auth_usecases.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.signUp});

  final SignUp signUp;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _mobileNumber.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final user = await widget.signUp(
        username: _username.text.trim(),
        email: _email.text.trim(),
        mobileNumber: _mobileNumber.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      setState(() => _message = 'Account created for ${user.username}!');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Registration failed: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const InputDecoration(labelText: 'Username'),
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
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a mobile number'
                          : null,
                ),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.length < 6
                          ? 'Use at least 6 characters'
                          : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Creating account...' : 'Sign up'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}