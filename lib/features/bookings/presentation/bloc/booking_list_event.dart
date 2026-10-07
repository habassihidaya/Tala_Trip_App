import 'package:equatable/equatable.dart';

enum BookingListAudience {
  traveler,
  owner,
}

sealed class BookingListEvent extends Equatable {
  const BookingListEvent();

  @override
  List<Object?> get props => [];
}

class BookingListStarted extends BookingListEvent {
  const BookingListStarted();
}

class BookingListRefreshRequested extends BookingListEvent {
  const BookingListRefreshRequested();
}

class BookingAcceptRequested extends BookingListEvent {
  final String bookingId;

  const BookingAcceptRequested(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class BookingRejectRequested extends BookingListEvent {
  final String bookingId;
  final String reason;

  const BookingRejectRequested({
    required this.bookingId,
    required this.reason,
  });

  @override
  List<Object?> get props => [
    bookingId,
    reason,
  ];
}

class BookingCancelRequested extends BookingListEvent {
  final String bookingId;

  const BookingCancelRequested(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}