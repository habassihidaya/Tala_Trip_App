import 'package:equatable/equatable.dart';

class BookingDates extends Equatable {
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const BookingDates._({
    required this.checkInDate,
    required this.checkOutDate,
  });

  factory BookingDates({
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) {
    // Keep only the selected calendar date.
    // UTC provides a consistent representation for date calculations.
    final checkIn = DateTime.utc(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
    );

    final checkOut = DateTime.utc(
      checkOutDate.year,
      checkOutDate.month,
      checkOutDate.day,
    );

    final nights = checkOut.difference(checkIn).inDays;

    if (nights < 1 || nights > 7) {
      throw ArgumentError(
        'A stay must be between 1 and 7 nights.',
      );
    }

    return BookingDates._(
      checkInDate: checkIn,
      checkOutDate: checkOut,
    );
  }

  int get nights => checkOutDate.difference(checkInDate).inDays;

  @override
  List<Object?> get props => [
    checkInDate,
    checkOutDate,
  ];
}
//receive two dates → remove the time → check the stay length → keep the valid dates