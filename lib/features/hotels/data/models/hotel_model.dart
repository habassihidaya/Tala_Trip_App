import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';

class HotelModel {
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
  const HotelModel({
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
  factory HotelModel.fromjson(Map<String, dynamic> map) {
    return HotelModel(
      id: map['id'] as String,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      wilaya: map['wilaya'] as String,
      adress: map['adress'] as String,
      phoneNumber: map['phoneNumber'] as double,
      images: List<String>.from(map['images'] as List),
      mapUrl: map['mapUrl'] as String,
      status: HotelStatus.values[map['status'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
      reviewedAt: DateTime.parse(map['reviewedAt'] as String),
      reviewedBy: map['reviewedBy'] as String,
      rejectedReason: map['rejectedReason'] as String,
    );
  }
  factory HotelModel.fromEntity(HotelEntity entity) {
    return HotelModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      description: entity.description,
      wilaya: entity.wilaya,
      adress: entity.adress,
      phoneNumber: entity.phoneNumber,
      images: entity.images,
      mapUrl: entity.mapUrl,
      status: entity.status,
      createdAt: entity.createdAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rejectedReason: entity.rejectedReason,
    );
  }
   HotelEntity toEntity() {
    return HotelEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      wilaya: wilaya,
      adress: adress,
      phoneNumber: phoneNumber,
      images: images,
      mapUrl: mapUrl,
      status: status,
      createdAt: createdAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectedReason: rejectedReason,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'wilaya': wilaya,
      'adress': adress,
      'phoneNumber': phoneNumber,
      'images': images,
      'mapUrl': mapUrl,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectedReason': rejectedReason,
    };
  }
}
