import 'package:equatable/equatable.dart';

import 'booking_entity.dart';

sealed class BookingSubmissionResolution extends Equatable {
  const BookingSubmissionResolution();
}

// The request succeeded: we found its saved booking.
class BookingSubmissionFound extends BookingSubmissionResolution {
  final BookingEntity booking;

  const BookingSubmissionFound({required this.booking});

  @override
  List<Object?> get props => [booking];
}

// No booking was created, and this request ID is now
// permanently blocked from creating one.
class BookingSubmissionClosed extends BookingSubmissionResolution {
  final String requestId;

  const BookingSubmissionClosed({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}
