import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status.dart';

import '../bloc/booking_list_bloc.dart';
import '../bloc/booking_list_event.dart';
import '../bloc/booking_list_state.dart';
import '../contact/booking_contact_launcher.dart';
import '../widgets/booking_card.dart';

class OwnerBookingsPage extends StatelessWidget {
  const OwnerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<BookingListBloc>(param1: BookingListAudience.owner)
            ..add(const BookingListStarted()),
      child: const _OwnerBookingsView(),
    );
  }
}

class _OwnerBookingsView extends StatelessWidget {
  const _OwnerBookingsView();
  Future<void> _refreshBookings(BuildContext context) async {
    final bloc = context.read<BookingListBloc>();

    if (bloc.isClosed || bloc.state.isBusy) return;

    final refreshFinished = bloc.stream
        .where(
          (state) =>
              state.status == BookingListStatus.loaded ||
              state.status == BookingListStatus.failure,
        )
        .take(1)
        .drain<void>();

    bloc.add(const BookingListRefreshRequested());

    await refreshFinished;
  }

  Future<void> _acceptBooking(
    BuildContext context,
    BookingEntity booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accept booking request?'),
          content: const Text(
            'Accept this request only after contacting the traveler '
            'and discussing the reservation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<BookingListBloc>().add(BookingAcceptRequested(booking.id));
    }
  }

  Future<void> _rejectBooking(
    BuildContext context,
    BookingEntity booking,
  ) async {
    var rejectionReason = '';
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject booking request'),
          content: Form(
            key: formKey,
            child: TextFormField(
              onSaved: (value) {
                rejectionReason = value?.trim() ?? '';
              },
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain why the request cannot be accepted.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a reason.';
                }

                if (value.trim().length > 1000) {
                  return 'Maximum 1,000 characters.';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final form = formKey.currentState;
                if (form == null || !form.validate()) return;

                form.save();
                Navigator.pop(dialogContext, rejectionReason);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null && context.mounted) {
      context.read<BookingListBloc>().add(
        BookingRejectRequested(bookingId: booking.id, reason: reason),
      );
    }
  }

  Future<void> _callTraveler(BuildContext context, String phoneNumber) async {
    final opened = await BookingContactLauncher.call(phoneNumber);

    if (!opened && context.mounted) {
      _showMessage(
        context,
        'Could not open the phone app. '
        'You can call $phoneNumber manually.',
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final opened = await BookingContactLauncher.openWhatsApp(phoneNumber);

    if (!opened && context.mounted) {
      _showMessage(
        context,
        'WhatsApp could not be opened. '
        'You can use the phone number manually.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingListBloc, BookingListState>(
      listener: (context, state) {
        if (state.message != null) {
          _showMessage(context, state.message!);
        }
      },
      builder: (context, state) {
        final showInitialLoading =
            state.status == BookingListStatus.initial ||
            (state.status == BookingListStatus.loading &&
                state.bookings.isEmpty);

        return Scaffold(
          appBar: AppBar(title: const Text('Booking requests')),
          body: RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () => _refreshBookings(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (showInitialLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == BookingListStatus.failure &&
                    state.bookings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorView(
                      message:
                          state.message ??
                          'Booking requests could not be loaded.',
                    ),
                  )
                else if (state.bookings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: const Text(
                          'No booking requests yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.all(16.r),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final booking = state.bookings[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < state.bookings.length - 1
                                ? 12.h
                                : 0,
                          ),
                          child: BookingCard(
                            key: ValueKey(booking.id),
                            booking: booking,
                            ownerView: true,
                            onCall: () =>
                                _callTraveler(context, booking.travelerPhone),
                            onWhatsApp: () =>
                                _openWhatsApp(context, booking.travelerPhone),
                            actions: _ownerActions(context, booking, state),
                          ),
                        );
                      }, childCount: state.bookings.length),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _ownerActions(
    BuildContext context,
    BookingEntity booking,
    BookingListState state,
  ) {
    if (booking.status != BookingStatus.pending) {
      return null;
    }

    final beforeCheckIn = DateTime.now().toUtc().isBefore(
      booking.checkInStartsAt,
    );

    if (!beforeCheckIn) {
      return const Text(
        'This request can no longer be accepted because '
        'the check-in time has started.',
      );
    }

    final busy = state.isBusy;
    final processingThisBooking = state.isActionLoading(booking.id);

    return Wrap(
      spacing: 12,
      children: [
        FilledButton.icon(
          onPressed: busy ? null : () => _acceptBooking(context, booking),
          icon: const Icon(Icons.check),
          label: Text(processingThisBooking ? 'Processing…' : 'Accept'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : () => _rejectBooking(context, booking),
          icon: const Icon(Icons.close),
          label: const Text('Reject'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.read<BookingListBloc>().add(
                const BookingListRefreshRequested(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
