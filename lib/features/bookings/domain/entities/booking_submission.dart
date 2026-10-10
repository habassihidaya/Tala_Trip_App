import 'package:equatable/equatable.dart';

import 'booking_draft.dart';

class BookingSubmission extends Equatable {
  final String requestId;
  final String travelerId;
  final BookingDraft draft;

  const BookingSubmission({
    required this.requestId,
    required this.travelerId,
    required this.draft,
  });

  @override
  List<Object?> get props => [requestId, travelerId, draft];
}
