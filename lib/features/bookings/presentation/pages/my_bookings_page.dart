import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      create: (_) => GetIt.instance<BookingListBloc>(
        param1: BookingListAudience.traveler,
      )..add(const BookingListStarted()),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

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
      context.read<BookingListBloc>().add(
        BookingCancelRequested(booking.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingListBloc, BookingListState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final showInitialLoading =
            state.status == BookingListStatus.initial ||
            (state.status == BookingListStatus.loading &&
                state.bookings.isEmpty);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My bookings'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.isBusy
                    ? null
                    : () => context.read<BookingListBloc>().add(
                          const BookingListRefreshRequested(),
                        ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: showInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : state.status == BookingListStatus.failure &&
                    state.bookings.isEmpty
              ? _ErrorView(
                  message: state.message ?? 'Bookings could not be loaded.',
                )
              : state.bookings.isEmpty
              ? const Center(
                  child: Text('You have no booking requests yet.'),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<BookingListBloc>().add(
                      const BookingListRefreshRequested(),
                    );

                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.bookings.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = state.bookings[index];

                      return BookingCard(
                        booking: booking,
                        ownerView: false,
                        actions: _travelerActions(
                          context,
                          booking,
                          state,
                        ),
                      );
                    },
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
        onPressed: state.isActionLoading(booking.id)
            ? null
            : () => _cancelBooking(context, booking),
        icon: const Icon(Icons.cancel_outlined),
        label: Text(
          state.isActionLoading(booking.id)
              ? 'Cancelling…'
              : 'Cancel booking',
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({
    required this.message,
  });

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