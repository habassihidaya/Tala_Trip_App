import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';

class HotelModel {
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

  const HotelModel({
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

  // Firestore data → model.
  factory HotelModel.fromJson(Map<String, dynamic> map) {
    return HotelModel(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      wilaya: map['wilaya'] as String,
      address: map['address'] as String,
      phoneNumber: map['phoneNumber'] as String,
      images: List<String>.from(map['images'] as List),
      mapUrl: map['mapUrl'] as String?,
      status: HotelStatus.values.byName(map['status'] as String),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: map['reviewedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  // Entity → model.
  factory HotelModel.fromEntity(HotelEntity entity) {
    return HotelModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      description: entity.description,
      wilaya: entity.wilaya,
      address: entity.address,
      phoneNumber: entity.phoneNumber,
      images: entity.images,
      mapUrl: entity.mapUrl,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rejectionReason: entity.rejectionReason,
    );
  }

  // Model → entity.
  HotelEntity toEntity() {
    return HotelEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      wilaya: wilaya,
      address: address,
      phoneNumber: phoneNumber,
      images: images,
      mapUrl: mapUrl,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
    );
  }

  // Model → Firestore data.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'wilaya': wilaya,
      'address': address,
      'phoneNumber': phoneNumber,
      'images': images,
      'mapUrl': mapUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewedAt':
          reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }
}
