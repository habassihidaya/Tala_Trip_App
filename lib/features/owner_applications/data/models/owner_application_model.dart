import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/owner_application_entity.dart';
import '../../domain/entities/owner_application_status.dart';

class OwnerApplicationModel {
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

  const OwnerApplicationModel({
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

  // Firestore document → model.
  // The document ID is passed separately from its fields.
  factory OwnerApplicationModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    return OwnerApplicationModel(
      id: id,
      userId: json['userId'] as String,
      applicantName: json['applicantName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      hotelName: json['hotelName'] as String,
      wilaya: json['wilaya'] as String,
      address: json['address'] as String,
      status: OwnerApplicationStatus.values.byName(
        json['status'] as String,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      reviewedAt: (json['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // Model → fields to store in Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'applicantName': applicantName,
      'phoneNumber': phoneNumber,
      'hotelName': hotelName,
      'wilaya': wilaya,
      'address': address,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt':
          reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  // Entity → model, before saving data.
  factory OwnerApplicationModel.fromEntity(
    OwnerApplicationEntity entity,
  ) {
    return OwnerApplicationModel(
      id: entity.id,
      userId: entity.userId,
      applicantName: entity.applicantName,
      phoneNumber: entity.phoneNumber,
      hotelName: entity.hotelName,
      wilaya: entity.wilaya,
      address: entity.address,
      status: entity.status,
      createdAt: entity.createdAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rejectionReason: entity.rejectionReason,
    );
  }

  // Model → entity, for the rest of the app.
  OwnerApplicationEntity toEntity() {
    return OwnerApplicationEntity(
      id: id,
      userId: userId,
      applicantName: applicantName,
      phoneNumber: phoneNumber,
      hotelName: hotelName,
      wilaya: wilaya,
      address: address,
      status: status,
      createdAt: createdAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
    );
  }
}