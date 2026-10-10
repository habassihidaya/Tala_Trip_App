import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tala_trip_app/core/widgets/gradient_button.dart';

import '../../domain/validation/auth_validation.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/auth_page_layout.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _pending = false;
  bool _resetPending = false;
  bool _showError = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _busy => _pending || context.read<AuthBloc>().state is AuthLoading;

  void _clearError(String _) {
    if (_showError) setState(() => _showError = false);
  }

  void _submit() {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = true;
      _resetPending = false;
      _showError = false;
    });
    context.read<AuthBloc>().add(
      SignInRequested(email: _email.text.trim(), password: _password.text),
    );
  }

  void _requestPasswordReset() {
    if (_busy || !(_emailFieldKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pending = true;
      _resetPending = true;
      _showError = false;
    });
    context.read<AuthBloc>().add(PasswordResetRequested(_email.text.trim()));
  }

  void _requestVerification({required bool resend}) {
    if (_busy) return;
    setState(() {
      _pending = true;
      _showError = false;
    });
    final bloc = context.read<AuthBloc>();
    if (resend) {
      bloc.add(ResendVerificationEmailRequested());
    } else {
      bloc.add(CheckEmailVerificationRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading) {
          setState(() {
            _pending = false;
            _resetPending = false;
            _showError = state is AuthError;
          });
        }
      },
      builder: (context, state) {
        final loading = _pending || state is AuthLoading;
        return AuthPageLayout(
          title: 'Welcome back',
          subtitle: 'Sign in to continue your journey.',
          spacious: true,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  key: _emailFieldKey,
                  controller: _email,
                  enabled: !loading,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidation.email,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: _clearError,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _password,
                  enabled: !loading,
                  obscureText: _hidePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: loading
                          ? null
                          : () =>
                                setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  autofillHints: const [AutofillHints.password],
                  validator: AuthValidation.signInPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: _clearError,
                  onFieldSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : _requestPasswordReset,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: loading ? null : _submit,
                  child: Text(
                    loading
                        ? (_resetPending
                              ? 'Sending reset link...'
                              : 'Please wait...')
                        : 'Sign in',
                  ),
                ),
                if (_showError && state is AuthError) ...[
                  const SizedBox(height: 16),
                  _notice(state.message, error: true),
                ],
                if (state is AuthProfileRequired) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: loading
                        ? null
                        : () => context.push('/account-type'),
                    child: const Text('Finish account setup'),
                  ),
                ],
                if (state is AuthPasswordResetEmailSent) ...[
                  const SizedBox(height: 16),
                  _notice(
                    'If an account uses this email, check your inbox for a password reset link.',
                  ),
                ],
                if (state is AuthVerificationRequired) ...[
                  const SizedBox(height: 20),
                  _notice(
                    state.message ??
                        'Please verify ${state.user.email} using the link we sent you.',
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => _requestVerification(resend: true),
                    child: const Text('Resend verification email'),
                  ),
                  OutlinedButton(
                    onPressed: loading
                        ? null
                        : () => _requestVerification(resend: false),
                    child: const Text("I've verified my email"),
                  ),
                ],
                if (state is AuthAuthenticated) ...[
                  const SizedBox(height: 16),
                  _notice('Signed in as ${state.user.username}.'),
                ],
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'New to TALA TRIP',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => context.push('/account-type'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notice(String message, {bool error = false}) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: error
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
