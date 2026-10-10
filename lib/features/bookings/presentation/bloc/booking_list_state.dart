import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';
import 'booking_list_event.dart';

enum BookingListStatus { initial, loading, loaded, actionLoading, failure }

class BookingListState extends Equatable {
  final BookingListAudience audience;
  final BookingListStatus status;
  final List<BookingEntity> bookings;
  final String? actionBookingId;
  final String? message;

  BookingListState({
    required this.audience,
    this.status = BookingListStatus.initial,
    List<BookingEntity> bookings = const [],
    this.actionBookingId,
    this.message,
  }) : bookings = List.unmodifiable(bookings);

  bool get isBusy =>
      status == BookingListStatus.loading ||
      status == BookingListStatus.actionLoading;

  bool get isEmpty => status == BookingListStatus.loaded && bookings.isEmpty;

  bool isActionLoading(String bookingId) {
    return status == BookingListStatus.actionLoading &&
        actionBookingId == bookingId;
  }

  BookingListState copyWith({
    BookingListStatus? status,
    List<BookingEntity>? bookings,
    String? actionBookingId,
    String? message,
    bool clearActionBookingId = false,
    bool clearMessage = false,
  }) {
    return BookingListState(
      audience: audience,
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      actionBookingId: clearActionBookingId
          ? null
          : actionBookingId ?? this.actionBookingId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    audience,
    status,
    bookings,
    actionBookingId,
    message,
  ];
}
