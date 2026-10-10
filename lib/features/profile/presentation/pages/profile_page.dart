import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../auth/presentation/blocs/auth_event.dart';
import '../../../auth/presentation/blocs/auth_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_name_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        return BlocProvider(
          key: ValueKey(authState.user.id),
          create: (_) => getIt<ProfileBloc>()..add(const ProfileRequested()),
          child: _ProfileView(userId: authState.user.id),
        );
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  final String userId;

  const _ProfileView({required this.userId});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _picker = ImagePicker();

  // Also blocks repeated taps before the BLoC emits its saving state.
  bool _pending = false;

  bool get _sessionAvailable {
    final authState = context.read<AuthBloc>().state;

    return authState is AuthAuthenticated &&
        authState.user.id == widget.userId &&
        !authState.isSigningOut;
  }

  bool get _canEdit {
    final profileState = context.read<ProfileBloc>().state;

    return !_pending &&
        _sessionAvailable &&
        profileState is ProfileLoaded &&
        profileState.user.id == widget.userId &&
        !profileState.isSaving;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editName(UserEntity user) async {
    if (!_canEdit) {
      return;
    }

    setState(() => _pending = true);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => EditProfileNameDialog(currentName: user.username),
    );

    if (!mounted) {
      return;
    }

    if (!_sessionAvailable || name == null || name == user.username) {
      setState(() => _pending = false);
      return;
    }

    context.read<ProfileBloc>().add(ProfileNameUpdateRequested(username: name));
  }

  Future<void> _choosePhoto() async {
    if (!_canEdit) {
      return;
    }

    setState(() => _pending = true);

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (!mounted) {
        return;
      }

      if (photo == null || !_sessionAvailable) {
        setState(() => _pending = false);
        return;
      }

      context.read<ProfileBloc>().add(
        ProfilePhotoUpdateRequested(filePath: photo.path),
      );
    } on PlatformException {
      if (!mounted) {
        return;
      }

      setState(() => _pending = false);
      _showMessage(
        'Could not open your gallery. Check photo permissions '
        'in your phone settings and try again.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _pending = false);
      _showMessage('Could not select this photo. Please try again.');
    }
  }

  void _onProfileChanged(BuildContext context, ProfileState state) {
    if (state is ProfileLoaded && !state.isSaving) {
      setState(() => _pending = false);

      final error = state.errorMessage;

      if (error != null) {
        _showMessage(error);
        return;
      }

      // Keep the user shown elsewhere in the app up to date.
      context.read<AuthBloc>().add(AuthUserProfileUpdated(user: state.user));

      final success = state.successMessage;

      if (success != null) {
        _showMessage(success);
      }
    } else if (state is ProfileLoadFailure) {
      setState(() => _pending = false);
    }
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.traveler => 'Traveler',
      UserRole.hotelOwner => 'Hotel owner',
      UserRole.admin => 'Admin',
    };
  }

  Widget _profilePhoto(String? url) {
    final theme = Theme.of(context);

    final placeholder = ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 64,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );

    return Semantics(
      label: 'Profile picture',
      image: true,
      child: SizedBox.square(
        dimension: 112,
        child: ClipOval(
          child: url == null || url.isEmpty
              ? placeholder
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return ColoredBox(
                      color: theme.colorScheme.primaryContainer,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return placeholder;
                  },
                ),
        ),
      ),
    );
  }

  Widget _profileDetails(ProfileLoaded state, {required bool busy}) {
    final user = state.user;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _profilePhoto(user.profileImageUrl)),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: busy ? null : _choosePhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              user.profileImageUrl == null
                  ? 'Add profile photo'
                  : 'Change profile photo',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.username,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _roleLabel(user.role),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (state.isSaving) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Saving your changes…', textAlign: TextAlign.center),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Name'),
                subtitle: Text(user.username),
                trailing: IconButton(
                  tooltip: 'Edit name',
                  onPressed: busy ? null : () => _editName(user),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone number'),
                subtitle: Text(user.mobileNumber),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: _onProfileChanged,
      builder: (context, profileState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final authenticated = authState is AuthAuthenticated;
            final signingOut = authenticated && authState.isSigningOut;
            final signOutError = authenticated ? authState.signOutError : null;

            final saving =
                profileState is ProfileLoaded && profileState.isSaving;

            final busy = _pending || saving || signingOut || !authenticated;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                automaticallyImplyLeading: false,
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        if (profileState is ProfileInitial ||
                            profileState is ProfileLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (profileState is ProfileLoadFailure)
                          Column(
                            children: [
                              const Icon(Icons.cloud_off_outlined, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                profileState.message,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () {
                                        context.read<ProfileBloc>().add(
                                          const ProfileRequested(),
                                        );
                                      },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try again'),
                              ),
                            ],
                          )
                        else if (profileState is ProfileLoaded)
                          _profileDetails(profileState, busy: busy),
                        const SizedBox(height: 32),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                    SignOutRequested(),
                                  );
                                },
                          icon: signingOut
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.logout),
                          label: Text(signingOut ? 'Signing out…' : 'Sign out'),
                        ),
                        if (signOutError != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              signOutError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
