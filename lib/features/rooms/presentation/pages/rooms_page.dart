import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import 'package:tala_trip_app/features/rooms/presentation/widgets/room_card.dart';
import '../../domain/entities/room_entity.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';

class RoomsPage extends StatelessWidget {
  final String hotelId;
  const RoomsPage({super.key, required this.hotelId});
  @override
  Widget build(BuildContext context) => BlocProvider<RoomBloc>(
    create: (_) => getIt<RoomBloc>(param1: hotelId)..add(LoadRooms()),
    child: const _RoomsView(),
  );
}

class _RoomsView extends StatelessWidget {
  const _RoomsView();

  Future<void> _edit(
    BuildContext context,
    RoomType type,
    RoomEntity? room,
  ) async {
    final bloc = context.read<RoomBloc>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _RoomEditor(type: type, original: room),
      ),
    );
  }

  Future<void> _delete(BuildContext context, RoomEntity room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${room.type.label} rooms?'),
        content: const Text(
          'This removes this room category and its price from the hotel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<RoomBloc>().add(DeleteRoomRequested(room));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    return BlocConsumer<RoomBloc, RoomState>(
      listener: (context, state) {
        if (state.actionSucceeded ||
            (state.error != null && state.catalog != null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.actionSucceeded ? 'Room inventory saved.' : state.error!,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final catalog = state.catalog;
        final ownsHotel =
            catalog != null &&
            auth is AuthAuthenticated &&
            auth.user.role == UserRole.hotelOwner &&
            auth.user.id == catalog.ownerId;
        final editable =
            catalog != null &&
            ownsHotel &&
            catalog.hotelStatus != HotelStatus.pending;
        final isTraveler =
            auth is AuthAuthenticated && auth.user.role == UserRole.traveler;

        final isAdmin =
            auth is AuthAuthenticated && auth.user.role == UserRole.admin;
        return PopScope(
          canPop: !state.saving,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Rooms and prices'),
              automaticallyImplyLeading: !state.saving,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: state.loading || state.saving
                      ? null
                      : () => context.read<RoomBloc>().add(LoadRooms()),
                ),
              ],
            ),
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : catalog == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.error ?? 'Rooms could not be loaded.'),
                          TextButton(
                            onPressed: () =>
                                context.read<RoomBloc>().add(LoadRooms()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        catalog.hotelName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Prices are in DZD, per room per night. Pay on arrival.',
                      ),
                      if (ownsHotel) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Room count is your total inventory, not availability for particular dates.',
                        ),
                        if (!editable)
                          const Text(
                            'Room changes are locked while the hotel is under review.',
                          ),
                      ],
                      if (state.saving) const LinearProgressIndicator(),
                      if (catalog.rooms.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No room types have been added yet.'),
                        ),
                      for (final room in catalog.rooms)
                        RoomCard(
                          room: room,
                          showInventory: ownsHotel || isAdmin,
                          canEdit: editable,
                          busy: state.saving,
                          onEdit: () => _edit(context, room.type, room),
                          onDelete: () => _delete(context, room),
                          onBook:
                              isTraveler &&
                                  catalog.hotelStatus == HotelStatus.approved
                              ? () {
                                  context.push(
                                    '/traveler/hotels/'
                                    '${Uri.encodeComponent(catalog.hotelId)}'
                                    '/book/${room.type.name}',
                                  );
                                }
                              : null,
                        ),
                      if (editable) ...[
                        const SizedBox(height: 16),
                        for (final type in RoomType.values)
                          if (!catalog.rooms.any((room) => room.type == type))
                            OutlinedButton.icon(
                              onPressed: state.saving
                                  ? null
                                  : () => _edit(context, type, null),
                              icon: const Icon(Icons.add),
                              label: Text('Add ${type.label} rooms'),
                            ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _RoomEditor extends StatefulWidget {
  final RoomType type;
  final RoomEntity? original;
  const _RoomEditor({required this.type, this.original});
  @override
  State<_RoomEditor> createState() => _RoomEditorState();
}

class _RoomEditorState extends State<_RoomEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _capacity;
  late final TextEditingController _price;
  late final TextEditingController _count;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _capacity = TextEditingController(
      text: '${widget.original?.capacity ?? widget.type.fixedCapacity ?? 2}',
    );
    _price = TextEditingController(text: widget.original?.priceText ?? '');
    _count = TextEditingController(text: '${widget.original?.totalRooms ?? 1}');
  }

  @override
  void dispose() {
    _capacity.dispose();
    _price.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RoomBloc, RoomState>(
    listener: (context, state) {
      if (state.actionSucceeded) {
        setState(() => _submitted = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).pop();
        });
      }
      if (state.error != null) setState(() => _submitted = false);
    },
    builder: (context, state) {
      final busy = _submitted || state.saving;
      return PopScope(
        canPop: !busy || state.actionSucceeded,
        child: AlertDialog(
          title: Text(
            '${widget.original == null ? 'Add' : 'Edit'} ${widget.type.label} rooms',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _capacity,
                    enabled: !busy,
                    readOnly: widget.type.fixedCapacity != null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Guests per room',
                    ),
                    validator: (value) {
                      final capacity = int.tryParse(value?.trim() ?? '');
                      return capacity == null || capacity < 1 || capacity > 20
                          ? 'Enter 1–20 guests.'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: _price,
                    enabled: !busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price per night (DZD)',
                    ),
                    validator: (value) =>
                        RoomEntity.parsePrice(value ?? '') == null
                        ? 'Enter 0.01–1,000,000 DZD (up to 2 decimals).'
                        : null,
                  ),
                  TextFormField(
                    controller: _count,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total number of rooms',
                    ),
                    validator: (value) {
                      final count = int.tryParse(value?.trim() ?? '');
                      return count == null || count < 1 || count > 10000
                          ? 'Enter 1–10,000 rooms.'
                          : null;
                    },
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _submitted = true);
                      context.read<RoomBloc>().add(
                        SaveRoomRequested(
                          RoomEntity(
                            type: widget.type,
                            capacity: int.parse(_capacity.text.trim()),
                            priceInCentimes: RoomEntity.parsePrice(
                              _price.text,
                            )!,
                            totalRooms: int.parse(_count.text.trim()),
                          ),
                          original: widget.original,
                        ),
                      );
                    },
              child: Text(busy ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      );
    },
  );
}
