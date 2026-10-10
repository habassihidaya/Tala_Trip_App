import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../../../core/constants/app_colors.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/domain/validation/auth_validation.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../helpers/password_strength_checker.dart';
import '../helpers/phone_number_helper.dart';
import '../widgets/dialing_code_picker.dart';
import '../widgets/auth_page_layout.dart';

class SignUpPage extends StatefulWidget {
  final UserRole role;

  const SignUpPage({super.key, required this.role});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmationFieldKey = GlobalKey<FormFieldState<String>>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _passwordStrengthChecker = PasswordStrengthChecker();

  Country _dialingRegion = Country.parse('DZ');
  IsoCode _phoneRegion = IsoCode.DZ;

  int? _passwordScore;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _confirmationTouched = false;
  bool _phoneTouched = false;
  bool _submissionPending = false;
  bool _showServerError = false;

  List<String> get _passwordUserInputs => [
    _username.text.trim(),
    _email.text.trim(),
    _email.text.trim().split('@').first,
    'tala',
    'tala trip',
  ].where((value) => value.isNotEmpty).toList();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _mobileNumber.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (!_showServerError) return;

    setState(() {
      _showServerError = false;
    });
  }

  void _updatePasswordStrength() {
    final score = _passwordStrengthChecker.score(
      _password.text,
      userInputs: _passwordUserInputs,
    );

    setState(() {
      _passwordScore = score;
      _showServerError = false;
    });
  }

  void _onPasswordChanged(String _) {
    _updatePasswordStrength();

    if (_confirmationTouched) {
      _confirmationFieldKey.currentState?.validate();
    }
  }

  String? _validateNewPassword(String? value) {
    final lengthError = AuthValidation.newPassword(value);
    if (lengthError != null) return lengthError;

    final score = _passwordStrengthChecker.score(
      value!,
      userInputs: _passwordUserInputs,
    );

    if (score == null || score <= 1) {
      return 'This password is too easy to guess. '
          'Try several unrelated words.';
    }

    return null;
  }

  Future<void> _chooseDialingCode() async {
    final selected = await showDialingCodePicker(
      context,
      selectedCode: _dialingRegion.countryCode,
    );

    if (!mounted || selected == null) return;

    // Match the picker's region to the phone parser's region.
    IsoCode? parserRegion;

    for (final region in IsoCode.values) {
      if (region.name == selected.countryCode) {
        parserRegion = region;
        break;
      }
    }

    if (parserRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This dialing option is not supported yet.'),
        ),
      );
      return;
    }

    setState(() {
      _dialingRegion = selected;
      _phoneRegion = parserRegion!;
      _showServerError = false;
    });

    if (_phoneTouched) {
      _phoneFieldKey.currentState?.validate();
    }
  }

  Future<void> _changeRole() async {
    final selected = await showDialog<UserRole>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose account type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(UserRole.traveler),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Traveler'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(dialogContext).pop(UserRole.hotelOwner),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Hotel owner'),
            ),
          ),
        ],
      ),
    );
    if (!mounted || selected == null || selected == widget.role) return;
    context.replace('/sign-up?role=${selected.name}');
  }

  void _submit() {
    // Also block taps before the BLoC has emitted AuthLoading.
    if (_submissionPending || context.read<AuthBloc>().state is AuthLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    _phoneTouched = true;
    _confirmationTouched = true;

    if (!_formKey.currentState!.validate()) return;

    final normalizedPhone = PhoneNumberHelper.normalize(
      _mobileNumber.text,
      country: _phoneRegion,
    );

    if (normalizedPhone == null) return;

    setState(() {
      _submissionPending = true;
      _showServerError = false;
    });

    context.read<AuthBloc>().add(
      SignUpRequested(
        username: _username.text.trim(),
        email: _email.text.trim(),
        mobileNumber: normalizedPhone,
        password: _password.text,
        role: widget.role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, current) =>
          current is AuthVerificationRequired || current is AuthError,
      listener: (context, state) {
        if (state is AuthVerificationRequired) {
          context.go('/sign-in');
          return;
        }

        if (state is AuthError) {
          setState(() {
            _submissionPending = false;
            _showServerError = true;
          });
        }
      },
      builder: (context, state) {
        final loading = _submissionPending || state is AuthLoading;

        return AuthPageLayout(
          title: 'Create your account',
          subtitle: 'A new journey starts with TALA.',
          onBack: loading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/account-type');
                  }
                },
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.role == UserRole.hotelOwner
                        ? AppColors.ownerSurface
                        : AppColors.infoSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.role == UserRole.hotelOwner
                            ? Icons.apartment_outlined
                            : Icons.luggage_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.role == UserRole.hotelOwner
                              ? 'Hotel owner'
                              : 'Traveler',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: loading ? null : _changeRole,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _username,
                  enabled: !loading,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => _updatePasswordStrength(),
                  validator: (value) {
                    final username = value?.trim() ?? '';

                    if (username.isEmpty) {
                      return 'Enter a username.';
                    }

                    if (username.length > 120) {
                      return 'Use no more than 120 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                  validator: AuthValidation.email,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => _updatePasswordStrength(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: _phoneFieldKey,
                  controller: _mobileNumber,
                  enabled: !loading,
                  decoration: InputDecoration(
                    labelText: 'Mobile number',
                    prefixIcon: TextButton(
                      onPressed: loading ? null : _chooseDialingCode,
                      child: Semantics(
                        label:
                            'Dialing code: ${_dialingRegion.name}, plus ${_dialingRegion.phoneCode}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+${_dialingRegion.phoneCode}'),
                            const Icon(Icons.expand_more, size: 20),
                          ],
                        ),
                      ),
                    ),
                    helperText:
                        'Use a local number or include its + dialing code.',
                    helperMaxLines: 2,
                    errorMaxLines: 3,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) {
                    _phoneTouched = true;
                    _clearServerError();
                  },
                  validator: (value) =>
                      PhoneNumberHelper.validate(value, country: _phoneRegion),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !loading,
                  obscureText: _hidePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText:
                        '8–128 characters, including spaces. '
                        'Avoid common or predictable passwords.',
                    helperMaxLines: 3,
                    errorMaxLines: 3,
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: loading
                          ? null
                          : () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: _validateNewPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: _onPasswordChanged,
                ),
                _buildPasswordStrength(),
                const SizedBox(height: 16),
                TextFormField(
                  key: _confirmationFieldKey,
                  controller: _confirmPassword,
                  enabled: !loading,
                  obscureText: _hideConfirmation,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorMaxLines: 2,
                    suffixIcon: IconButton(
                      tooltip: _hideConfirmation
                          ? 'Show confirmation password'
                          : 'Hide confirmation password',
                      onPressed: loading
                          ? null
                          : () {
                              setState(() {
                                _hideConfirmation = !_hideConfirmation;
                              });
                            },
                      icon: Icon(
                        _hideConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) =>
                      AuthValidation.confirmPassword(value, _password.text),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) {
                    _confirmationTouched = true;
                    _clearServerError();
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                Text(
                  "We'll send you an email to verify your account.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            Text('Creating account...'),
                          ],
                        )
                      : Text(
                          state is AuthProfileRequired
                              ? 'Finish account setup'
                              : 'Create account',
                        ),
                ),
                if (_showServerError && state is AuthError) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: loading ? null : () => context.go('/sign-in'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrength() {
    final score = _passwordScore;

    if (score == null) {
      return const SizedBox.shrink();
    }

    final String label;
    final Color color;
    final String hint;

    if (score <= 1) {
      label = 'Weak';
      color = Colors.red.shade800;
      hint = 'Avoid common passwords, repeated patterns, and personal details.';
    } else if (score <= 3) {
      label = 'Medium';
      color = const Color.fromARGB(255, 227, 159, 75);
      hint = 'Try adding more unrelated words to your passphrase.';
    } else {
      label = 'Strong';
      color = Colors.green.shade800;
      hint = 'Use this password only for TALA Trip.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password strength: $label',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(hint),
        ],
      ),
    );
  }
}
