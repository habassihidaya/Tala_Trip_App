import 'package:equatable/equatable.dart';

import 'owner_application_status.dart';

class OwnerApplicationEntity extends Equatable {
  final String id;
  final String userId;
  final String applicantName;
  final String phoneNumber;
  final String hotelName;
  final String wilaya;
  final String address;
  final OwnerApplicationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const OwnerApplicationEntity({
    required this.id,
    required this.userId,
    required this.applicantName,
    required this.phoneNumber,
    required this.hotelName,
    required this.wilaya,
    required this.address,
    required this.createdAt,
    this.status = OwnerApplicationStatus.pending,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    applicantName,
    phoneNumber,
    hotelName,
    wilaya,
    address,
    status,
    createdAt,
    reviewedAt,
    reviewedBy,
    rejectionReason,
  ];
}