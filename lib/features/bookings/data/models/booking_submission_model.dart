import 'package:tala_trip_app/features/rooms/domain/entities/room_entity.dart';

import '../../domain/entities/booking_dates.dart';
import '../../domain/entities/booking_draft.dart';
import '../../domain/entities/booking_submission.dart';

class BookingSubmissionModel {
  final BookingSubmission _submission;

  const BookingSubmissionModel.fromEntity(
    BookingSubmission submission,
  ) : _submission = submission;

  BookingSubmission toEntity() => _submission;

  factory BookingSubmissionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported saved booking submission format.',
      );
    }

    final draftJson = Map<String, dynamic>.from(
      json['draft'] as Map,
    );

    return BookingSubmissionModel.fromEntity(
      BookingSubmission(
        requestId: json['requestId'] as String,
        travelerId: json['travelerId'] as String,
        draft: BookingDraft(
          hotelId: draftJson['hotelId'] as String,
          roomType: RoomType.values.byName(
            draftJson['roomType'] as String,
          ),
          dates: BookingDates(
            checkInDate: _readDate(draftJson['checkInDate']),
            checkOutDate: _readDate(draftJson['checkOutDate']),
          ),
          guests: draftJson['guests'] as int,
          reviewedNightlyPriceInCentimes:
              draftJson['reviewedNightlyPriceInCentimes'] as int,
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final draft = _submission.draft;

    return {
      'schemaVersion': 1,
      'requestId': _submission.requestId,
      'travelerId': _submission.travelerId,
      'draft': {
        'hotelId': draft.hotelId,
        'roomType': draft.roomType.name,
        'checkInDate': draft.dates.checkInDate.toIso8601String(),
        'checkOutDate': draft.dates.checkOutDate.toIso8601String(),
        'guests': draft.guests,
        'reviewedNightlyPriceInCentimes':
            draft.reviewedNightlyPriceInCentimes,
      },
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is! String) {
      throw const FormatException(
        'A saved submission date must be text.',
      );
    }

    final date = DateTime.tryParse(value);

    if (date == null ||
        !date.isUtc ||
        date != DateTime.utc(date.year, date.month, date.day) ||
        date.toIso8601String() != value) {
      throw const FormatException(
        'A saved submission date has an invalid format.',
      );
    }

    return date;
  }
}