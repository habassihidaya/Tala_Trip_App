import 'package:equatable/equatable.dart';

sealed class BookingFormEvent extends Equatable {
  const BookingFormEvent();

  @override
  List<Object?> get props => [];
}

// The form opened: check for saved unresolved submissions.
class BookingFormStarted extends BookingFormEvent {
  const BookingFormStarted();
}

// The traveler changed the dates or number of guests.
class BookingFormDetailsChanged extends BookingFormEvent {
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guests;

  const BookingFormDetailsChanged({
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
  });

  @override
  List<Object?> get props => [checkInDate, checkOutDate, guests];
}

// Check availability and obtain the current price.
class BookingFormAvailabilityRequested extends BookingFormEvent {
  const BookingFormAvailabilityRequested();
}

// The traveler deliberately pressed the submission button.
class BookingFormSubmitted extends BookingFormEvent {
  const BookingFormSubmitted();
}

// Resolve an uncertain request without creating a booking.
class BookingFormRecoveryRequested extends BookingFormEvent {
  const BookingFormRecoveryRequested();
}
