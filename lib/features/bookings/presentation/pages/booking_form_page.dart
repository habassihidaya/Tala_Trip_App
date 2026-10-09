import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../bloc/booking_form_bloc.dart';
import '../bloc/booking_form_event.dart';
import '../bloc/booking_form_state.dart';

import 'package:tala_trip_app/core/time/algeria_time.dart';

class BookingFormPage extends StatelessWidget {
  final String hotelId;
  final RoomType roomType;

  const BookingFormPage({
    super.key,
    required this.hotelId,
    required this.roomType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GetIt.instance<BookingFormBloc>(param1: hotelId, param2: roomType)
            ..add(const BookingFormStarted()),
      child: _BookingFormView(roomType: roomType),
    );
  }
}

class _BookingFormView extends StatelessWidget {
  final RoomType roomType;

  const _BookingFormView({required this.roomType});

  Future<void> _pickCheckInDate(BuildContext context) async {
    final bloc = context.read<BookingFormBloc>();
    final state = bloc.state;

    final today = GetIt.instance<AlgeriaTime>().today(now: DateTime.now());

    final firstDate = today.add(const Duration(days: 1));
    final lastDate = today.add(const Duration(days: 365));

    final initialDate = _validInitialDate(
      state.checkInDate ?? firstDate,
      firstDate,
      lastDate,
    );

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: 'Select check-in date',
    );

    if (picked == null || !context.mounted) return;

    DateTime? checkOut = state.checkOutDate;

    if (checkOut == null || !checkOut.isAfter(picked)) {
      checkOut = picked.add(const Duration(days: 1));
    }

    bloc.add(
      BookingFormDetailsChanged(
        checkInDate: picked,
        checkOutDate: checkOut,
        guests: state.guests,
      ),
    );
  }

  Future<void> _pickCheckOutDate(BuildContext context) async {
    final bloc = context.read<BookingFormBloc>();
    final state = bloc.state;
    final checkIn = state.checkInDate;

    if (checkIn == null) {
      _showMessage(context, 'Select the check-in date first.');
      return;
    }

    final firstDate = checkIn.add(const Duration(days: 1));
    final lastDate = checkIn.add(const Duration(days: 7));

    final initialDate = _validInitialDate(
      state.checkOutDate ?? firstDate,
      firstDate,
      lastDate,
    );

    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: 'Select check-out date',
    );

    if (picked == null || !context.mounted) return;

    bloc.add(
      BookingFormDetailsChanged(
        checkInDate: checkIn,
        checkOutDate: picked,
        guests: state.guests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingFormBloc, BookingFormState>(
      listener: (context, state) {
        if (state.status == BookingFormStatus.submitted &&
            state.booking != null) {
          _showMessage(context, 'Booking request sent successfully.');
        }
      },
      builder: (context, state) {
        final bloc = context.read<BookingFormBloc>();
        final maxGuests = roomType.fixedCapacity ?? 20;

        return Scaffold(
          appBar: AppBar(title: Text('Book ${roomType.label} room')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Choose your stay dates and number of guests.'),
              const SizedBox(height: 20),

              _DateButton(
                label: 'Check-in',
                value: state.checkInDate == null
                    ? 'Select date'
                    : _formatDate(state.checkInDate!),
                enabled: state.canEdit,
                onPressed: () => _pickCheckInDate(context),
              ),
              const SizedBox(height: 12),

              _DateButton(
                label: 'Check-out',
                value: state.checkOutDate == null
                    ? 'Select date'
                    : _formatDate(state.checkOutDate!),
                enabled: state.canEdit && state.checkInDate != null,
                onPressed: () => _pickCheckOutDate(context),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: state.guests <= maxGuests ? state.guests : null,
                decoration: const InputDecoration(
                  labelText: 'Number of guests',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var guests = 1; guests <= maxGuests; guests++)
                    DropdownMenuItem(
                      value: guests,
                      child: Text('$guests guest${guests == 1 ? '' : 's'}'),
                    ),
                ],
                onChanged: state.canEdit
                    ? (guests) {
                        if (guests == null) return;

                        bloc.add(
                          BookingFormDetailsChanged(
                            checkInDate: state.checkInDate,
                            checkOutDate: state.checkOutDate,
                            guests: guests,
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 20),

              if (state.hasUnresolvedSubmission) _RecoveryCard(state: state),

              if (state.message != null)
                _MessageCard(
                  message: state.message!,
                  isError:
                      state.status == BookingFormStatus.failure ||
                      state.status == BookingFormStatus.uncertain,
                ),
              if (state.status == BookingFormStatus.failure &&
                  !state.recoveryChecked)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      bloc.add(const BookingFormStarted());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading booking form'),
                  ),
                ),

              if (state.status == BookingFormStatus.submitted &&
                  state.booking != null)
                _SubmittedCard(state: state),

              if (state.isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),

              if (state.availability != null &&
                  state.status != BookingFormStatus.submitted)
                _PriceCard(state: state),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: state.canEdit && !state.isBusy
                    ? () => bloc.add(const BookingFormAvailabilityRequested())
                    : null,
                child: Text(
                  state.availability == null
                      ? 'Check availability and price'
                      : 'Refresh availability and price',
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: state.canSubmit
                    ? () => bloc.add(const BookingFormSubmitted())
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send booking request'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final BookingFormState state;

  const _RecoveryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BookingFormBloc>();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous request needs checking',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We do not know whether Firebase received your previous '
              'request. Check it before sending another request.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.canRecover
                  ? () => bloc.add(const BookingFormRecoveryRequested())
                  : null,
              child: const Text('Check previous request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final BookingFormState state;

  const _PriceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final availability = state.availability!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price review', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${availability.room.priceText} DZD per night'),
            Text('${availability.dates.nights} night(s)'),
            const SizedBox(height: 8),
            Text(
              '${_formatCentimes(availability.totalPriceInCentimes)} DZD total',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${availability.availableRooms} room(s) available '
              'for the complete stay',
            ),
            const SizedBox(height: 8),
            const Text('Payment is made at the hotel.'),
          ],
        ),
      ),
    );
  }
}

class _SubmittedCard extends StatelessWidget {
  final BookingFormState state;

  const _SubmittedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final booking = state.booking!;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request sent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Request ID: ${booking.requestId}'),
            Text('Current status: ${booking.status.name}'),
            const SizedBox(height: 8),
            const Text(
              'This means the hotel received the request. '
              'It is confirmed only after the hotel owner accepts it.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label: $value'),
          const Icon(Icons.calendar_month_outlined),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

DateTime _validInitialDate(
  DateTime value,
  DateTime firstDate,
  DateTime lastDate,
) {
  if (value.isBefore(firstDate)) return firstDate;
  if (value.isAfter(lastDate)) return lastDate;
  return value;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _formatCentimes(int value) {
  final dinars = value ~/ 100;
  final centimes = (value % 100).toString().padLeft(2, '0');

  return '$dinars.$centimes';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
