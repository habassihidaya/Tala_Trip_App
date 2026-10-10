import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_data_source.dart';

class LocalFavoritesDataSource implements FavoritesDataSource {
  final SharedPreferences _preferences;

  // Process saves one at a time so they cannot overwrite each other.
  Future<void> _pendingWrite = Future<void>.value();

  LocalFavoritesDataSource(this._preferences);

  String _storageKey(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('A user ID is required.');
    }

    return 'favorite_hotels_$userId';
  }

  Set<String> _readIds(String key) {
    return (_preferences.getStringList(key) ?? <String>[]).toSet();
  }

  @override
  Future<Set<String>> getFavoriteIds({required String userId}) async {
    final key = _storageKey(userId);

    await _pendingWrite;

    return _readIds(key);
  }

  @override
  Future<void> addFavorite({required String userId, required String hotelId}) {
    return _updateFavorite(userId: userId, hotelId: hotelId, shouldAdd: true);
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String hotelId,
  }) {
    return _updateFavorite(userId: userId, hotelId: hotelId, shouldAdd: false);
  }

  Future<void> _updateFavorite({
    required String userId,
    required String hotelId,
    required bool shouldAdd,
  }) {
    final operation = _pendingWrite.then((_) async {
      final key = _storageKey(userId);

      if (hotelId.trim().isEmpty) {
        throw ArgumentError('A hotel ID is required.');
      }

      final ids = _readIds(key);
      final changed = shouldAdd ? ids.add(hotelId) : ids.remove(hotelId);

      if (!changed) {
        return;
      }

      final saved = await _preferences.setStringList(key, ids.toList()..sort());

      if (!saved) {
        throw StateError('Could not save your favorites.');
      }
    });

    // A failed save must not block future attempts.
    // The original operation still reports its error to the caller.
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );

    return operation;
  }
}
