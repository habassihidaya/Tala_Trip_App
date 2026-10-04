import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tala_trip_app/core/errors/exceptions.dart';
import 'package:tala_trip_app/features/hotels/data/data_sources/hotel_data_sources.dart';
import 'package:tala_trip_app/features/hotels/data/models/hotel_model.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';

class FirebaseHotelDataSource implements HotelDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseHotelDataSource(this._auth, this._firestore);

  @override
  Future<HotelModel> createHotelDraft({
    required String name,
    required String description,
    required String wilaya,
    required String address,
    required String phoneNumber,
    required List<String> images,
    String? mapUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final document = _firestore.collection('hotels').doc();
    final now = DateTime.now();
    final trimmedMapUrl = mapUrl?.trim();

    final hotel = HotelModel(
      id: document.id,
      ownerId: user.uid,
      name: name.trim(),
      description: description.trim(),
      wilaya: wilaya.trim(),
      address: address.trim(),
      phoneNumber: phoneNumber.trim(),
      images: List<String>.from(images),
      mapUrl: trimmedMapUrl == null || trimmedMapUrl.isEmpty
          ? null
          : trimmedMapUrl,
      status: HotelStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    await document.set(hotel.toJson());

    return hotel;
  }

  @override
  Future<List<HotelModel>> getMyHotels() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final snapshot = await _firestore
        .collection('hotels')
        .where('ownerId', isEqualTo: user.uid)
        .get();

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({
        ...document.data(),
        'id': document.id,
      });
    }).toList();

    // Display the newest hotels first.
    hotels.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );

    return hotels;
  }

  @override
  Future<HotelModel> getHotelById(String id) async {
    if (_auth.currentUser == null) {
      throw const UnauthenticatedException();
    }

    final document = await _firestore.collection('hotels').doc(id).get();
    final data = document.data();

    if (data == null) {
      throw const HotelNotFoundException();
    }

    return HotelModel.fromJson({
      ...data,
      'id': document.id,
    });
  }

  @override
  Future<void> updateHotelDraft(HotelModel hotel) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final document = _firestore.collection('hotels').doc(hotel.id);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();

      if (data == null) {
        throw const HotelNotFoundException();
      }

      // Check ownership using the saved document.
      if (data['ownerId'] != user.uid) {
        throw const HotelOperationException(
          'You can only edit your own hotels.',
        );
      }

      final status = data['status'];

      if (status != HotelStatus.draft.name &&
          status != HotelStatus.rejected.name) {
        throw const HotelOperationException(
          'Only draft or rejected hotels can be edited.',
        );
      }

      final trimmedMapUrl = hotel.mapUrl?.trim();

      // Saving edits returns the hotel to draft.
      // Ownership and creation time remain unchanged.
      transaction.update(document, {
        'name': hotel.name.trim(),
        'description': hotel.description.trim(),
        'wilaya': hotel.wilaya.trim(),
        'address': hotel.address.trim(),
        'phoneNumber': hotel.phoneNumber.trim(),
        'images': List<String>.from(hotel.images),
        'mapUrl': trimmedMapUrl == null || trimmedMapUrl.isEmpty
            ? null
            : trimmedMapUrl,
        'status': HotelStatus.draft.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
      });
    });
  }

  @override
  Future<void> deleteHotelDraft(String id) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final document = _firestore.collection('hotels').doc(id);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();

      if (data == null) {
        throw const HotelNotFoundException();
      }

      if (data['ownerId'] != user.uid) {
        throw const HotelOperationException(
          'You can only delete your own hotels.',
        );
      }

      if (data['status'] != HotelStatus.draft.name) {
        throw const HotelOperationException(
          'Only draft hotels can be deleted.',
        );
      }

      transaction.delete(document);
    });
  }

  @override
  Future<void> submitHotelForReview(String id) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final document = _firestore.collection('hotels').doc(id);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();

      if (data == null) {
        throw const HotelNotFoundException();
      }

      if (data['ownerId'] != user.uid) {
        throw const HotelOperationException(
          'You can only submit your own hotels.',
        );
      }

      if (data['status'] != HotelStatus.draft.name) {
        throw const HotelOperationException(
          'Only draft hotels can be submitted for review.',
        );
      }

      final hotel = HotelModel.fromJson({
        ...data,
        'id': snapshot.id,
      });

      // Drafts may be incomplete, but submissions need full details.
      if (hotel.name.trim().isEmpty ||
          hotel.description.trim().isEmpty ||
          hotel.wilaya.trim().isEmpty ||
          hotel.address.trim().isEmpty ||
          hotel.phoneNumber.trim().isEmpty) {
        throw const HotelOperationException(
          'Please complete the hotel name, description, wilaya, '
          'address and phone number before submitting.',
        );
      }

      bool isWebUrl(String value) {
        final uri = Uri.tryParse(value.trim());

        return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty;
      }

      if (hotel.images.isEmpty ||
          hotel.images.any((url) => !isWebUrl(url))) {
        throw const HotelOperationException(
          'Please add at least one photo and use valid photo URLs.',
        );
      }

      final mapUrl = hotel.mapUrl;

      if (mapUrl != null && !isWebUrl(mapUrl)) {
        throw const HotelOperationException(
          'Please provide a valid map URL or leave it empty.',
        );
      }

      transaction.update(document, {
        'status': HotelStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
      });
    });
  }

  // Firestore rules must also enforce admin permissions.
  Future<String> _requireAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    final profile = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (profile.data()?['role'] != 'admin') {
      throw const HotelOperationException(
        'Only an admin can perform this action.',
      );
    }

    return user.uid;
  }

  @override
  Future<List<HotelModel>> getPendingHotels() async {
    await _requireAdmin();

    final snapshot = await _firestore
        .collection('hotels')
        .where('status', isEqualTo: HotelStatus.pending.name)
        .get();

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({
        ...document.data(),
        'id': document.id,
      });
    }).toList();

    // Review the oldest submissions first.
    hotels.sort(
      (first, second) => first.updatedAt.compareTo(second.updatedAt),
    );

    return hotels;
  }

  @override
  Future<void> approveHotel(String id) async {
    final adminId = await _requireAdmin();
    final document = _firestore.collection('hotels').doc(id);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();

      if (data == null) {
        throw const HotelNotFoundException();
      }

      if (data['status'] != HotelStatus.pending.name) {
        throw const HotelOperationException(
          'Only pending hotels can be approved.',
        );
      }

      transaction.update(document, {
        'status': HotelStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
    });
  }

  @override
  Future<void> rejectHotel(String id, String reason) async {
    final adminId = await _requireAdmin();
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      throw const HotelOperationException(
        'Please provide a rejection reason.',
      );
    }

    final document = _firestore.collection('hotels').doc(id);

    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);
      final data = snapshot.data();

      if (data == null) {
        throw const HotelNotFoundException();
      }

      if (data['status'] != HotelStatus.pending.name) {
        throw const HotelOperationException(
          'Only pending hotels can be rejected.',
        );
      }

      transaction.update(document, {
        'status': HotelStatus.rejected.name,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': trimmedReason,
      });
    });
  }

  @override
  Future<List<HotelModel>> getApprovedHotels() async {
    if (_auth.currentUser == null) {
      throw const UnauthenticatedException();
    }

    final snapshot = await _firestore
        .collection('hotels')
        .where('status', isEqualTo: HotelStatus.approved.name)
        .get();

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({
        ...document.data(),
        'id': document.id,
      });
    }).toList();

    // Display hotels alphabetically.
    hotels.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );

    return hotels;
  }
}