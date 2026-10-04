import '../../domain/entities/room_catalog.dart';

class RoomState {
  final RoomCatalog? catalog;
  final bool loading;
  final bool saving;
  final bool actionSucceeded;
  final String? error;
  const RoomState({
    this.catalog,
    this.loading = false,
    this.saving = false,
    this.actionSucceeded = false,
    this.error,
  });
}
