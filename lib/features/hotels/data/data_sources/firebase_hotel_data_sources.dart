import 'package:tala_trip_app/features/hotels/domain/validation/hotel_validation.dart';
import 'package:tala_trip_app/features/rooms/data/models/room_model.dart';

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

    _validateDraft(
      name,
      description,
      wilaya,
      address,
      phoneNumber,
      images,
      mapUrl,
    );
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
      phoneNumber: HotelValidation.normalizePhone(phoneNumber),
      images: List<String>.from(images),
      mapUrl: trimmedMapUrl == null || trimmedMapUrl.isEmpty
          ? null
          : trimmedMapUrl,
      status: HotelStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    // A transaction performs a server read first and fails offline, instead
    // of leaving the form waiting indefinitely for a queued offline write.
    await _firestore.runTransaction<void>((transaction) async {
      final profile = await transaction.get(
        _firestore.collection('users').doc(user.uid),
      );
      if (profile.data()?['role'] != 'hotelOwner') {
        throw const HotelOperationException(
          'Only hotel owners can create hotels.',
        );
      }
      transaction.set(document, {
        ...hotel.toJson(),
        'rooms': <String, dynamic>{},
      });
    });

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
        .get(const GetOptions(source: Source.server));

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({...document.data(), 'id': document.id});
    }).toList();

    // Display the newest hotels first.
    hotels.sort((first, second) => second.createdAt.compareTo(first.createdAt));

    return hotels;
  }

  @override
  Future<HotelModel> getHotelById(String id) async {
    if (_auth.currentUser == null) {
      throw const UnauthenticatedException();
    }

    final document = await _firestore
        .collection('hotels')
        .doc(id)
        .get(const GetOptions(source: Source.server));
    final data = document.data();

    if (data == null) {
      throw const HotelNotFoundException();
    }

    return HotelModel.fromJson({...data, 'id': document.id});
  }

  @override
  Future<void> updateHotelDraft(HotelModel hotel) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw const UnauthenticatedException();
    }

    _validateDraft(
      hotel.name,
      hotel.description,
      hotel.wilaya,
      hotel.address,
      hotel.phoneNumber,
      hotel.images,
      hotel.mapUrl,
    );
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

      if ((data['updatedAt'] as Timestamp).toDate() != hotel.updatedAt) {
        throw const HotelOperationException(
          'This hotel changed since you opened it. Return to details and reload before editing.',
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
        'phoneNumber': HotelValidation.normalizePhone(hotel.phoneNumber),
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

      final hotel = HotelModel.fromJson({...data, 'id': snapshot.id});

      _validateSubmission(hotel, data);

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
        .get(const GetOptions(source: Source.server));

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
        .get(const GetOptions(source: Source.server));

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({...document.data(), 'id': document.id});
    }).toList();

    // Review the oldest submissions first.
    hotels.sort((first, second) => first.updatedAt.compareTo(second.updatedAt));

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

      _validateSubmission(
        HotelModel.fromJson({...data, 'id': snapshot.id}),
        data,
      );
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

    if (trimmedReason.isEmpty || trimmedReason.length > 1000) {
      throw const HotelOperationException(
        'Provide a rejection reason of 1–1,000 characters.',
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
        .get(const GetOptions(source: Source.server));

    final hotels = snapshot.docs.map((document) {
      return HotelModel.fromJson({...document.data(), 'id': document.id});
    }).toList();

    // Display hotels alphabetically.
    hotels.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );

    return hotels;
  }

  void _validateDraft(
    String name,
    String description,
    String wilaya,
    String address,
    String phone,
    List<String> images,
    String? mapUrl,
  ) {
    final message = HotelValidation.draft(
      name: name,
      description: description,
      wilaya: wilaya,
      address: address,
      phoneNumber: phone,
      photoCount: images.length,
      mapUrl: mapUrl,
    );
    if (message != null) throw HotelOperationException(message);
    if (images.any((url) => !HotelValidation.validImage(url))) {
      throw const HotelOperationException(
        'Choose valid uploaded Cloudinary photos.',
      );
    }
  }

  void _validateSubmission(HotelModel hotel, Map<String, dynamic> data) {
    _validateDraft(
      hotel.name,
      hotel.description,
      hotel.wilaya,
      hotel.address,
      hotel.phoneNumber,
      hotel.images,
      hotel.mapUrl,
    );
    if (hotel.description.trim().isEmpty ||
        hotel.wilaya.isEmpty ||
        hotel.address.trim().isEmpty ||
        hotel.phoneNumber.trim().isEmpty ||
        hotel.images.isEmpty) {
      throw const HotelOperationException(
        'Complete the description, wilaya, address, phone number and at least one photo.',
      );
    }
    final rooms = Map<String, dynamic>.from(data['rooms'] as Map? ?? {});
    if (rooms.isEmpty) {
      throw const HotelOperationException(
        'Add at least one room type before submitting for review.',
      );
    }
    for (final entry in rooms.entries) {
      RoomModel.fromJson(
        entry.key,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
  }
}
