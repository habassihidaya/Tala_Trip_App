import 'package:equatable/equatable.dart';

enum RoomType {
  single('Single', 1),
  double('Double', 2),
  suite('Suite', null);

  final String label;
  final int? fixedCapacity;

  const RoomType(this.label, this.fixedCapacity);
}

/// Inventory for a room category, not an individual numbered room.
class RoomEntity extends Equatable {
  final RoomType type;
  final int capacity;
  final int priceInCentimes;
  final int totalRooms;
  final List<String> images;

  const RoomEntity({
    required this.type,
    required this.capacity,
    required this.priceInCentimes,
    required this.totalRooms,
    this.images = const [],
  });

  String get priceText =>
      '${priceInCentimes ~/ 100}.'
      '${(priceInCentimes % 100).toString().padLeft(2, '0')}';

  String? validate() {
    if (capacity < 1 || capacity > 4) {
      return 'Capacity must be between 1 and 4 guests.';
    }

    if (type.fixedCapacity != null && capacity != type.fixedCapacity) {
      return '${type.label} rooms must have capacity '
          '${type.fixedCapacity}.';
    }

    if (priceInCentimes < 1 || priceInCentimes > 100000000) {
      return 'Enter a price greater than 0 and at most 1,000,000 DZD.';
    }

    if (totalRooms < 1 || totalRooms > 10000) {
      return 'Room count must be between 1 and 10,000.';
    }

    if (images.length > 10) {
      return 'You can add up to 10 photos per room type.';
    }

    for (final image in images) {
      final uri = Uri.tryParse(image);

      if (image.length > 2048 ||
          RegExp(r'\s').hasMatch(image) ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'res.cloudinary.com' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          uri.path.length <= 1) {
        return 'One of the room photos has an invalid URL.';
      }
    }

    return null;
  }

  /// Converts a DZD price into centimes without decimal rounding.
  static int? parsePrice(String input) {
    final text = input.trim().replaceAll(',', '.');

    if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final fraction = parts.length == 2 ? parts[1].padRight(2, '0') : '00';

    final value = int.parse(parts[0]) * 100 + int.parse(fraction);

    return value > 0 && value <= 100000000 ? value : null;
  }

  @override
  List<Object?> get props => [
    type,
    capacity,
    priceInCentimes,
    totalRooms,
    images,
  ];
}
