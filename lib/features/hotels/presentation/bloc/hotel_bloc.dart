import 'package:tala_trip_app/features/hotels/domain/validation/hotel_validation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:tala_trip_app/core/errors/failures.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/hotel_usecases.dart';
import 'package:tala_trip_app/features/hotels/domain/usecases/upload_hotel_photo.dart';

import 'hotel_event.dart';
import 'hotel_state.dart';

class HotelBloc extends Bloc<HotelEvent, HotelState> {
  final Map<String, String> _uploadedPhotos = {};
  List<HotelEntity> _searchableHotels = const [];
  String? _selectedWilaya;
  String _searchQuery = '';
  bool _hasSearchableHotels = false;
  bool _isApprovedList = false;
  final CreateHotelDraft _createHotelDraft;
  final GetMyHotels _getMyHotels;
  final GetHotelById _getHotelById;
  final UpdateHotelDraft _updateHotelDraft;
  final DeleteHotelDraft _deleteHotelDraft;
  final SubmitHotelForReview _submitHotelForReview;
  final GetPendingHotels _getPendingHotels;
  final ApproveHotel _approveHotel;
  final RejectHotel _rejectHotel;
  final GetApprovedHotels _getApprovedHotels;
  final UploadHotelPhoto _uploadHotelPhoto;

  HotelBloc({
    required this._createHotelDraft,
    required this._getMyHotels,
    required this._getHotelById,
    required this._updateHotelDraft,
    required this._deleteHotelDraft,
    required this._submitHotelForReview,
    required this._getPendingHotels,
    required this._approveHotel,
    required this._rejectHotel,
    required this._getApprovedHotels,
    required this._uploadHotelPhoto,
  }) : super(HotelInitialState()) {
    // Process events one at a time.
    on<HotelEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  Future<void> _onEvent(HotelEvent event, Emitter<HotelState> emit) async {
    if (event is SearchHotelsEvent) {
      _searchQuery = event.query;

      if (_hasSearchableHotels &&
          (state is HotelsLoadedState || state is HotelsEmptyState)) {
        _emitFilteredHotels(emit);
      }

      return;
    }

    if (event is FilterApprovedHotelsEvent) {
      if (!_isApprovedList ||
          !_hasSearchableHotels ||
          (state is! HotelsLoadedState && state is! HotelsEmptyState)) {
        return;
      }

      _selectedWilaya = event.wilaya;
      _emitFilteredHotels(emit);
      return;
    }

    emit(HotelLoadingState());

    if (event is CreateHotelDraftEvent) {
      final validation = HotelValidation.draft(
        name: event.name,
        description: event.description,
        wilaya: event.wilaya,
        address: event.address,
        phoneNumber: event.phoneNumber,
        photoCount: event.photoPaths.length,
        mapUrl: event.mapUrl,
      );
      if (validation != null) {
        emit(HotelErrorState(message: validation));
        return;
      }
      final imageUrls = <String>[];

      for (final path in event.photoPaths) {
        final uploadResult = await _uploadOnce(path);

        Failure? uploadFailure;

        uploadResult.fold<void>(
          (failure) {
            uploadFailure = failure;
          },
          (url) {
            imageUrls.add(url);
          },
        );

        final failure = uploadFailure;

        if (failure != null) {
          emit(HotelErrorState(message: failure.message));
          return;
        }
      }

      final result = await _createHotelDraft(
        name: event.name,
        description: event.description,
        wilaya: event.wilaya,
        address: event.address,
        phoneNumber: event.phoneNumber,
        images: imageUrls,
        mapUrl: event.mapUrl,
      );

      result.fold<void>(
        (failure) {
          emit(HotelErrorState(message: failure.message));
        },
        (hotel) {
          emit(HotelDraftCreatedState(hotel: hotel));
        },
      );

      return;
    }
    if (event is GetMyHotelsEvent) {
      final result = await _getMyHotels();

      _storeSearchableHotels(result, emit, approvedList: false);

      return;
    }

    if (event is GetHotelByIdEvent) {
      final result = await _getHotelById(event.id);

      result.fold<void>(
        (failure) => emit(HotelErrorState(message: failure.message)),
        (hotel) => emit(HotelDetailsLoadedState(hotel: hotel)),
      );
      return;
    }

    if (event is UpdateHotelDraftEvent) {
      final hotel = event.hotel;

      // Only drafts and rejected hotels can be edited.
      if (hotel.status.name != 'draft' && hotel.status.name != 'rejected') {
        emit(
          HotelErrorState(
            message: 'Only draft or rejected hotels can be edited.',
          ),
        );
        return;
      }

      final validation = HotelValidation.draft(
        name: hotel.name,
        description: hotel.description,
        wilaya: hotel.wilaya,
        address: hotel.address,
        phoneNumber: hotel.phoneNumber,
        photoCount: hotel.images.length + event.photoPaths.length,
        mapUrl: hotel.mapUrl,
      );
      if (validation != null) {
        emit(HotelErrorState(message: validation));
        return;
      }
      // Keep the existing remote photos selected in the form.
      final imageUrls = <String>[...hotel.images];

      // Upload any newly selected phone photos.
      for (final path in event.photoPaths) {
        final uploadResult = await _uploadOnce(path);

        Failure? uploadFailure;

        uploadResult.fold<void>(
          (failure) {
            uploadFailure = failure;
          },
          (url) {
            imageUrls.add(url);
          },
        );

        final failure = uploadFailure;

        if (failure != null) {
          emit(HotelErrorState(message: failure.message));
          return;
        }
      }

      // Combine the edited information with the final photo URLs.
      final updatedHotel = HotelEntity(
        id: hotel.id,
        ownerId: hotel.ownerId,
        name: hotel.name,
        description: hotel.description,
        wilaya: hotel.wilaya,
        address: hotel.address,
        phoneNumber: hotel.phoneNumber,
        images: List.unmodifiable(imageUrls),
        mapUrl: hotel.mapUrl,
        status: hotel.status,
        createdAt: hotel.createdAt,
        updatedAt: hotel.updatedAt,
        reviewedAt: hotel.reviewedAt,
        reviewedBy: hotel.reviewedBy,
        rejectionReason: hotel.rejectionReason,
      );

      final result = await _updateHotelDraft(updatedHotel);

      _emitActionResult(
        result,
        emit,
        hotelId: hotel.id,
        action: HotelAction.updated,
      );
      return;
    }

    if (event is DeleteHotelDraftEvent) {
      final result = await _deleteHotelDraft(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.deleted,
      );
      return;
    }

    if (event is SubmitHotelForReviewEvent) {
      final result = await _submitHotelForReview(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.submitted,
      );
      return;
    }

    if (event is GetPendingHotelsEvent) {
      final result = await _getPendingHotels();
      _emitHotelList(result, emit);
      return;
    }

    if (event is ApproveHotelEvent) {
      final result = await _approveHotel(event.id);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.approved,
      );
      return;
    }

    if (event is RejectHotelEvent) {
      final reason = event.reason.trim();

      if (reason.isEmpty) {
        emit(HotelErrorState(message: 'Please provide a rejection reason.'));
        return;
      }

      final result = await _rejectHotel(event.id, reason);

      _emitActionResult(
        result,
        emit,
        hotelId: event.id,
        action: HotelAction.rejected,
      );
      return;
    }

    if (event is GetApprovedHotelsEvent) {
      final result = await _getApprovedHotels();

      _storeSearchableHotels(result, emit, approvedList: true);

      return;
    }

    emit(HotelErrorState(message: 'Unsupported hotel action.'));
  }

  void _storeSearchableHotels(
    Either<Failure, List<HotelEntity>> result,
    Emitter<HotelState> emit, {
    required bool approvedList,
  }) {
    _isApprovedList = approvedList;

    if (!approvedList) {
      _selectedWilaya = null;
    }

    result.fold<void>(
      (failure) {
        _searchableHotels = const [];
        _hasSearchableHotels = false;
        emit(HotelErrorState(message: failure.message));
      },
      (hotels) {
        _searchableHotels = List<HotelEntity>.unmodifiable(hotels);
        _hasSearchableHotels = true;
        _emitFilteredHotels(emit);
      },
    );
  }

  void _emitFilteredHotels(Emitter<HotelState> emit) {
    final query = _normalizeSearch(_searchQuery);
    final words = query.isEmpty ? const <String>[] : query.split(' ');

    final hotels = _searchableHotels
        .where((hotel) {
          final matchesWilaya =
              !_isApprovedList ||
              _selectedWilaya == null ||
              _normalizeSearch(hotel.wilaya) ==
                  _normalizeSearch(_selectedWilaya!);

          if (!matchesWilaya) return false;

          final searchableText = _normalizeSearch(
            '${hotel.name} ${hotel.wilaya} ${hotel.address}',
          );

          return words.every(searchableText.contains);
        })
        .toList(growable: false);

    if (hotels.isEmpty) {
      emit(HotelsEmptyState());
    } else {
      emit(HotelsLoadedState(hotels: hotels));
    }
  }

  // Shared handling for the three hotel-list operations.
  void _emitHotelList(
    Either<Failure, List<HotelEntity>> result,
    Emitter<HotelState> emit,
  ) {
    result.fold<void>(
      (failure) => emit(HotelErrorState(message: failure.message)),
      (hotels) {
        if (hotels.isEmpty) {
          emit(HotelsEmptyState());
        } else {
          emit(HotelsLoadedState(hotels: hotels));
        }
      },
    );
  }

  // Shared handling for operations that return success without data.
  String _normalizeSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\balger\b'), 'algiers')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('œ', 'oe')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<Either<Failure, String>> _uploadOnce(String path) async {
    final cached = _uploadedPhotos[path];

    if (cached != null) return Right(cached);

    final result = await _uploadHotelPhoto(path);

    result.fold<void>((_) {}, (url) {
      _uploadedPhotos[path] = url;
    });

    return result;
  }

  void _emitActionResult(
    Either<Failure, Unit> result,
    Emitter<HotelState> emit, {
    required String hotelId,
    required HotelAction action,
  }) {
    result.fold<void>(
      (failure) => emit(HotelErrorState(message: failure.message)),
      (_) => emit(HotelActionSuccessState(hotelId: hotelId, action: action)),
    );
  }
}
