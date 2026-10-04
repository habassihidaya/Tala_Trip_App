import 'package:equatable/equatable.dart';

import 'hotel_status.dart';

class HotelEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String wilaya;
  final String address;
  final String phoneNumber;
  final List<String> images;
  final String? mapUrl;
  final HotelStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const HotelEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.wilaya,
    required this.address,
    required this.phoneNumber,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.status = HotelStatus.draft,
    this.mapUrl,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        description,
        wilaya,
        address,
        phoneNumber,
        images,
        mapUrl,
        status,
        createdAt,
        updatedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
      ];
}