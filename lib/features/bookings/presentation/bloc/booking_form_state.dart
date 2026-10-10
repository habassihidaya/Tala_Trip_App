import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_availability.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_submission.dart';

enum BookingFormStatus {
  initial,
  loading,
  editing,
  checkingAvailability,
  ready,
  submitting,
  recovering,
  submitted,
  failure,
  uncertain,
}

class BookingFormState extends Equatable {
  final BookingFormStatus status;

  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guests;

  // True only after successfully reading local recovery records.
  final bool recoveryChecked;

  final BookingAvailability? availability;
  final List<BookingSubmission> unresolvedSubmissions;

  // A server-confirmed result of submission or recovery.
  // Its booking status can still be pending.
  final BookingEntity? booking;

  final String? message;

  BookingFormState({
    this.status = BookingFormStatus.initial,
    this.checkInDate,
    this.checkOutDate,
    this.guests = 1,
    this.recoveryChecked = false,
    this.availability,
    List<BookingSubmission> unresolvedSubmissions = const [],
    this.booking,
    this.message,
  }) : unresolvedSubmissions = List.unmodifiable(unresolvedSubmissions);

  bool get isBusy =>
      status == BookingFormStatus.loading ||
      status == BookingFormStatus.checkingAvailability ||
      status == BookingFormStatus.submitting ||
      status == BookingFormStatus.recovering;

  bool get hasUnresolvedSubmission => unresolvedSubmissions.isNotEmpty;

  bool get canEdit =>
      recoveryChecked &&
      !isBusy &&
      !hasUnresolvedSubmission &&
      status != BookingFormStatus.submitted;

  bool get canSubmit =>
      canEdit &&
      status == BookingFormStatus.ready &&
      availability != null &&
      availability!.hasAvailability;

  bool get canRecover => hasUnresolvedSubmission && !isBusy;

  BookingFormState copyWith({
    BookingFormStatus? status,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    bool? recoveryChecked,
    BookingAvailability? availability,
    List<BookingSubmission>? unresolvedSubmissions,
    BookingEntity? booking,
    String? message,
    bool clearCheckInDate = false,
    bool clearCheckOutDate = false,
    bool clearAvailability = false,
    bool clearBooking = false,
    bool clearMessage = false,
  }) {
    return BookingFormState(
      status: status ?? this.status,
      checkInDate: clearCheckInDate ? null : checkInDate ?? this.checkInDate,
      checkOutDate: clearCheckOutDate
          ? null
          : checkOutDate ?? this.checkOutDate,
      guests: guests ?? this.guests,
      recoveryChecked: recoveryChecked ?? this.recoveryChecked,
      availability: clearAvailability
          ? null
          : availability ?? this.availability,
      unresolvedSubmissions:
          unresolvedSubmissions ?? this.unresolvedSubmissions,
      booking: clearBooking ? null : booking ?? this.booking,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    checkInDate,
    checkOutDate,
    guests,
    recoveryChecked,
    availability,
    unresolvedSubmissions,
    booking,
    message,
  ];
}
