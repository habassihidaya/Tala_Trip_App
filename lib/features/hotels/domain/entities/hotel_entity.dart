
import 'package:equatable/equatable.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';

class HotelEntity  extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String wilaya;
  final String adress;
  final double phoneNumber;
  final List<String> images;
  final String mapUrl;
  final HotelStatus status;
  final DateTime createdAt;
  final DateTime reviewedAt;
  final String reviewedBy;
  final String rejectedReason;


  HotelEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.wilaya,
    required this.adress,
    required this.phoneNumber,
    required this.images,
    required this.mapUrl,
    required this.status,
    required this.createdAt,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.rejectedReason,
  });
  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    description,
    wilaya,
    adress,
    phoneNumber,
    images,
    mapUrl,
    status,
    createdAt,
    reviewedAt,
    reviewedBy,
    rejectedReason
  ];
}