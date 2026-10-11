import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tala_trip_app/core/constants/app_colors.dart';
import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/hotels/domain/validation/hotel_validation.dart';
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
  String _rejectionReason = '';
  bool _actionRequested = false;

  void _reload() {
    context.read<HotelBloc>().add(GetHotelByIdEvent(id: widget.hotelId));
  }

  Future<void> _openMap(String mapUrl) async {
    try {
      final trimmedUrl = mapUrl.trim();
      final uri = Uri.tryParse(trimmedUrl);

      if (uri == null || !HotelValidation.validMap(trimmedUrl)) {
        throw const FormatException('Invalid map location');
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw StateError('Could not open map');
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the map. Please try again later.'),
        ),
      );
    }
  }

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
            'This hotel draft and its room inventory will be permanently '
            'deleted. This cannot be undone.',
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

                  // False avoids the owner's submission-success message.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.pop(false);
                  });

                  return;
                }

                if (state.action == HotelAction.submitted) {
                  // The owner's list shows the submission message.
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          SizedBox(height: 16.h),
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
                  final mapUrl = hotel.mapUrl?.trim() ?? '';
                  final hasValidMap =
                      mapUrl.isNotEmpty && HotelValidation.validMap(mapUrl);
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
                      padding: EdgeInsets.all(16.r),
                      children: [
                        // Photos.
                        _HotelPhotoGallery(images: hotel.images),
                        SizedBox(height: 20.h),

                        // Hotel name.
                        Text(
                          hotel.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 16.h),

                        // Location and contact.
                        Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: AppColors.primary,
                                size: 22.r,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  hotel.wilaya,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DetailField(label: 'Address', value: hotel.address),
                        _DetailField(
                          label: 'Phone number',
                          value: hotel.phoneNumber,
                        ),

                        _DetailField(
                          label: 'Description',
                          value: hotel.description,
                        ),

                        if (user?.role == UserRole.hotelOwner ||
                            user?.role == UserRole.admin)
                          _DetailField(
                            label: 'Status',
                            value: hotel.status.name,
                          ),

                        // Map button: the raw URL is never displayed.
                        OutlinedButton.icon(
                          onPressed: hasValidMap
                              ? () => _openMap(mapUrl)
                              : null,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open map'),
                        ),
                        if (!hasValidMap) ...[
                          SizedBox(height: 8.h),
                          Text(
                            mapUrl.isEmpty
                                ? 'Location not provided.'
                                : 'The saved map location is invalid.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        SizedBox(height: 8.h),

                        // Rooms are accessible even without a map URL.
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final role = user?.role;
                            final prefix = role == UserRole.admin
                                ? 'admin'
                                : role == UserRole.hotelOwner
                                ? 'owner'
                                : 'traveler';

                            await context.push(
                              '/$prefix/hotels/'
                              '${Uri.encodeComponent(hotel.id)}/rooms',
                            );

                            if (!mounted) return;

                            _reload();
                          },
                          icon: const Icon(Icons.bed_outlined),
                          label: Text(
                            canEdit ||
                                    canDelete ||
                                    user?.role == UserRole.hotelOwner
                                ? 'Manage rooms and prices'
                                : 'View rooms and prices',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Rejection information.
                        if (hotel.status.name == 'rejected') ...[
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Changes requested',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 8.h),
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
                          SizedBox(height: 16.h),
                        ],

                        // Owner: edit draft or rejected hotel.
                        if (canEdit) ...[
                          SizedBox(height: 8.h),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final updated = await context.push<bool>(
                                '/owner/hotels/'
                                '${Uri.encodeComponent(hotel.id)}/edit',
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

                        // Owner: submit draft.
                        if (canSubmit) ...[
                          SizedBox(height: 8.h),
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
                          SizedBox(height: 8.h),
                          const Text(
                            'Add at least one room type, then submit. '
                            'An admin will review your hotel before '
                            'it appears to travelers.',
                            textAlign: TextAlign.center,
                          ),
                        ],

                        // Owner: delete draft.
                        if (canDelete) ...[
                          SizedBox(height: 16.h),
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

                        // Admin: review pending hotel.
                        if (canReview) ...[
                          const Divider(),
                          SizedBox(height: 12.h),
                          Text(
                            'Review this hotel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8.h),
                          const Text(
                            'Approve the listing or explain what the '
                            'owner needs to correct.',
                          ),
                          SizedBox(height: 16.h),
                          FilledButton.icon(
                            onPressed: _approveHotel,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Approve hotel'),
                          ),
                          SizedBox(height: 8.h),
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
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 4.h),
          SelectableText(value.trim().isEmpty ? 'Not provided' : value),
        ],
      ),
    );
  }
}

class _HotelPhotoGallery extends StatelessWidget {
  final List<String> images;

  const _HotelPhotoGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        height: 240.h,
        child: images.isEmpty
            ? _placeholder(context, 'No photos available.')
            : PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        semanticLabel: 'Hotel photo ${index + 1}',
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const ColoredBox(
                            color: AppColors.infoSurface,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, _, _) =>
                            _placeholder(context, 'Could not load this photo.'),
                      ),
                      if (images.length > 1)
                        Positioned(
                          right: 12.w,
                          bottom: 12.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${index + 1} / ${images.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, String message) {
    return ColoredBox(
      color: AppColors.infoSurface,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hotel_outlined, size: 40.r, color: AppColors.primary),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
