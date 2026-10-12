import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status.dart';
import '../bloc/booking_list_bloc.dart';
import '../bloc/booking_list_event.dart';
import '../bloc/booking_list_state.dart';
import '../widgets/booking_card.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<BookingListBloc>(param1: BookingListAudience.traveler)
            ..add(const BookingListStarted()),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  Future<void> _refreshBookings(BuildContext context) async {
    final bloc = context.read<BookingListBloc>();

    if (bloc.isClosed || bloc.state.isBusy) return;

    // Subscribe before sending the event so we cannot miss completion.
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

  Future<void> _cancelBooking(
    BuildContext context,
    BookingEntity booking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text(
            'The hotel owner will see that you cancelled this request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep booking'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel booking'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<BookingListBloc>().add(BookingCancelRequested(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingListBloc, BookingListState>(
      listenWhen: (previous, current) {
        return current.message != null && current.message != previous.message;
      },
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        final showInitialLoading =
            state.status == BookingListStatus.initial ||
            (state.status == BookingListStatus.loading &&
                state.bookings.isEmpty);

        return Scaffold(
          appBar: AppBar(title: const Text('My bookings')),
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
                      message: state.message ?? 'Bookings could not be loaded.',
                      onRetry: () => _refreshBookings(context),
                    ),
                  )
                else if (state.bookings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: const Text(
                          'You have no booking requests yet.',
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
                            ownerView: false,
                            actions: _travelerActions(context, booking, state),
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

  Widget? _travelerActions(
    BuildContext context,
    BookingEntity booking,
    BookingListState state,
  ) {
    final canCancel =
        (booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed) &&
        DateTime.now().toUtc().isBefore(booking.checkInStartsAt);

    if (!canCancel) return null;

    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: state.isBusy ? null : () => _cancelBooking(context, booking),
        icon: const Icon(Icons.cancel_outlined),
        label: Text(
          state.isActionLoading(booking.id) ? 'Cancelling…' : 'Cancel booking',
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
