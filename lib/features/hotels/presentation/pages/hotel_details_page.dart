import 'package:url_launcher/url_launcher.dart';
import 'package:tala_trip_app/features/hotels/domain/validation/hotel_validation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';

class HotelDetailsPage extends StatelessWidget {
  final String hotelId;

  const HotelDetailsPage({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HotelBloc>(
      create: (_) => getIt<HotelBloc>()..add(GetHotelByIdEvent(id: hotelId)),
      child: _HotelDetailsView(hotelId: hotelId),
    );
  }
}

class _HotelDetailsView extends StatefulWidget {
  final String hotelId;

  const _HotelDetailsView({required this.hotelId});

  @override
  State<_HotelDetailsView> createState() => _HotelDetailsViewState();
}

class _HotelDetailsViewState extends State<_HotelDetailsView> {
  // Keep the reason while this page is open, including after a failure.
  String _rejectionReason = '';
  bool _actionRequested = false;

  void _reload() {
    context.read<HotelBloc>().add(GetHotelByIdEvent(id: widget.hotelId));
  }

  // Check the current state before dispatching an admin action.
  bool _canReview() {
    final authState = context.read<AuthBloc>().state;
    final hotelState = context.read<HotelBloc>().state;

    return authState is AuthAuthenticated &&
        authState.user.role == UserRole.admin &&
        hotelState is HotelDetailsLoadedState &&
        hotelState.hotel.id == widget.hotelId &&
        hotelState.hotel.status.name == 'pending';
  }

  void _approveHotel() {
    if (!_canReview() || _actionRequested) return;
    setState(() => _actionRequested = true);

    context.read<HotelBloc>().add(ApproveHotelEvent(id: widget.hotelId));
  }

  Future<void> _rejectHotel() async {
    if (!_canReview() || _actionRequested) return;

    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject hotel'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: TextFormField(
                initialValue: _rejectionReason,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Explain what the owner needs to correct.',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _rejectionReason = value;
                },
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      value.trim().length > 1000) {
                    return 'Enter a reason of 1–1,000 characters.';
                  }

                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.of(dialogContext).pop(_rejectionReason.trim());
              },
              child: const Text('Reject hotel'),
            ),
          ],
        );
      },
    );

    if (!mounted || reason == null) return;
    if (!_canReview() || _actionRequested) return;
    setState(() => _actionRequested = true);

    context.read<HotelBloc>().add(
      RejectHotelEvent(id: widget.hotelId, reason: reason),
    );
  }

  Future<void> _deleteDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete draft?'),
          content: const Text(
            'This hotel draft and its room inventory will be permanently deleted. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final authState = context.read<AuthBloc>().state;
    final bloc = context.read<HotelBloc>();
    final hotelState = bloc.state;

    if (authState is! AuthAuthenticated ||
        authState.user.role != UserRole.hotelOwner ||
        hotelState is! HotelDetailsLoadedState ||
        hotelState.hotel.id != widget.hotelId ||
        hotelState.hotel.ownerId != authState.user.id ||
        hotelState.hotel.status.name != 'draft') {
      return;
    }

    if (_actionRequested) return;
    setState(() => _actionRequested = true);
    bloc.add(DeleteHotelDraftEvent(id: widget.hotelId));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocBuilder<HotelBloc, HotelState>(
      builder: (context, outerState) {
        final busy =
            outerState is HotelLoadingState ||
            (_actionRequested &&
                outerState is! HotelActionSuccessState &&
                outerState is! HotelErrorState);
        return PopScope(
          canPop: !busy,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Hotel details'),
              automaticallyImplyLeading: !busy,
            ),
            body: BlocConsumer<HotelBloc, HotelState>(
              listener: (context, state) {
                if (state is HotelErrorState) {
                  setState(() => _actionRequested = false);
                }
                if (state is! HotelActionSuccessState) return;
                if (state.action == HotelAction.deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hotel draft deleted.')),
                  );

                  // The list refreshes on return.
                  // False avoids showing its "submitted for review" message.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.pop(false);
                  });
                  return;
                }

                if (state.action == HotelAction.submitted) {
                  // The owner's list already shows the submission message.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.pop(true);
                  });
                  return;
                }

                if (state.action == HotelAction.approved ||
                    state.action == HotelAction.rejected) {
                  final message = state.action == HotelAction.approved
                      ? 'Hotel approved.'
                      : 'Hotel rejected.';

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));

                  // Returning refreshes the pending-hotels list.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.pop(true);
                  });
                }
              },
              builder: (context, state) {
                if (state is HotelInitialState ||
                    state is HotelLoadingState ||
                    state is HotelActionSuccessState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is HotelErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Reload hotel'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is HotelDetailsLoadedState) {
                  final hotel = state.hotel;
                  final mapUrl = hotel.mapUrl;
                  final rejectionReason = hotel.rejectionReason;

                  final canSubmit =
                      user != null &&
                      user.role == UserRole.hotelOwner &&
                      user.id == hotel.ownerId &&
                      hotel.status.name == 'draft';

                  final canReview =
                      user != null &&
                      user.role == UserRole.admin &&
                      hotel.status.name == 'pending';

                  final canEdit =
                      user != null &&
                      user.role == UserRole.hotelOwner &&
                      user.id == hotel.ownerId &&
                      (hotel.status.name == 'draft' ||
                          hotel.status.name == 'rejected');
                  final canDelete =
                      user != null &&
                      user.role == UserRole.hotelOwner &&
                      user.id == hotel.ownerId &&
                      hotel.status.name == 'draft';

                  return AbsorbPointer(
                    absorbing: busy,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          hotel.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('${hotel.wilaya} • ${hotel.status.name}'),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final role = user?.role;
                            final prefix = role == UserRole.admin
                                ? 'admin'
                                : role == UserRole.hotelOwner
                                ? 'owner'
                                : 'traveler';
                            await context.push(
                              '/$prefix/hotels/${Uri.encodeComponent(hotel.id)}/rooms',
                            );
                            if (context.mounted) _reload();
                          },
                          icon: const Icon(Icons.bed_outlined),
                          label: Text(
                            canEdit ||
                                    canDelete ||
                                    user?.role == UserRole.hotelOwner
                                ? 'Manage rooms and prices'
                                : 'View rooms and prices',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Photos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (hotel.images.isEmpty)
                          const Text('No photos saved for this hotel.')
                        else
                          ...hotel.images.map(
                            (url) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }

                                        return const SizedBox(
                                          height: 220,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    if (kDebugMode) {
                                      debugPrint('Hotel photo URL: $url');
                                      debugPrint('Hotel photo error: $error');
                                    }

                                    return const SizedBox(
                                      height: 220,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.broken_image_outlined,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text('Could not load this photo.'),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _DetailField(
                          label: 'Description',
                          value: hotel.description,
                        ),
                        _DetailField(label: 'Wilaya', value: hotel.wilaya),
                        _DetailField(label: 'Address', value: hotel.address),
                        _DetailField(
                          label: 'Phone number',
                          value: hotel.phoneNumber,
                        ),
                        if (mapUrl != null && mapUrl.trim().isNotEmpty) ...[
                          _DetailField(label: 'Map link', value: mapUrl),
                          if (HotelValidation.validMap(mapUrl))
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final opened = await launchUrl(
                                    Uri.parse(mapUrl),
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!opened) {
                                    throw StateError(
                                      'No map application available',
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not open Maps. You can copy the link above.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Open Google Maps'),
                            ),
                        ],
                        if (hotel.status.name == 'rejected') ...[
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Changes requested',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rejectionReason == null ||
                                            rejectionReason.trim().isEmpty
                                        ? 'No rejection reason is available.'
                                        : rejectionReason,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (canEdit) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final updated = await context.push<bool>(
                                '/owner/hotels/${Uri.encodeComponent(hotel.id)}/edit',
                                extra: hotel,
                              );

                              if (!context.mounted) return;

                              if (updated == true) {
                                _reload();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Changes saved as a draft.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit hotel'),
                          ),
                        ],

                        // Only the owner can submit their own draft.
                        if (canSubmit) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              if (_actionRequested) return;
                              setState(() => _actionRequested = true);
                              context.read<HotelBloc>().add(
                                SubmitHotelForReviewEvent(id: hotel.id),
                              );
                            },
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('Submit for review'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add at least one room type, then submit. An admin will review your hotel before '
                            'it appears to travelers.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (canDelete) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _deleteDraft,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete draft'),
                          ),
                        ],

                        // Admin review controls for pending hotels.
                        if (canReview) ...[
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            'Review this hotel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Approve the listing or explain what the '
                            'owner needs to correct.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _approveHotel,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve hotel'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _rejectHotel,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Reject hotel'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return const Center(child: Text('No hotel details available.'));
              },
            ),
          ),
        );
      },
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          SelectableText(value.trim().isEmpty ? 'Not provided' : value),
        ],
      ),
    );
  }
}
