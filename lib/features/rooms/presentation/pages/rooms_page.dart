import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import 'package:tala_trip_app/features/rooms/presentation/widgets/room_card.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  Future<void> _refreshRooms(BuildContext context) async {
    final bloc = context.read<RoomBloc>();

    if (bloc.isClosed || bloc.state.loading || bloc.state.saving) {
      return;
    }

    final refreshFinished = bloc.stream
        .skipWhile((state) => !state.loading)
        .where((state) => !state.loading && !state.saving)
        .take(1)
        .drain<void>();

    bloc.add(LoadRooms());

    await refreshFinished;
  }

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
    final setupMode =
        GoRouterState.of(context).uri.queryParameters['setup'] == 'true';

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
            ),
            bottomNavigationBar: setupMode && ownsHotel
                ? SafeArea(
                    minimum: EdgeInsets.all(16.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Each room type is saved when you tap Save. '
                          'You can finish your draft later.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.loading || state.saving
                                ? null
                                : () => context.pop(),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            body: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () => _refreshRooms(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (catalog == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.error ?? 'Rooms could not be loaded.',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12.h),
                              TextButton(
                                onPressed: () => _refreshRooms(context),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.all(16.r),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            catalog.hotelName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 12.h),
                          const Text(
                            'Prices are in DZD, per room per night. '
                            'Pay on arrival.',
                          ),
                          if (ownsHotel) ...[
                            SizedBox(height: 8.h),
                            const Text(
                              'Room count is your total inventory, '
                              'not availability for particular dates.',
                            ),
                            if (!editable)
                              const Text(
                                'Room changes are locked while '
                                'the hotel is under review.',
                              ),
                          ],
                          if (state.saving) const LinearProgressIndicator(),
                          if (catalog.rooms.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: const Text(
                                'No room types have been added yet.',
                              ),
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
                                      catalog.hotelStatus ==
                                          HotelStatus.approved
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
                            SizedBox(height: 16.h),
                            for (final type in RoomType.values)
                              if (!catalog.rooms.any(
                                (room) => room.type == type,
                              ))
                                Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: OutlinedButton.icon(
                                    onPressed: state.saving
                                        ? null
                                        : () => _edit(context, type, null),
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      'Add ${type.label} rooms',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                          ],
                        ]),
                      ),
                    ),
                ],
              ),
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
  bool _isPickingImages = false;
  bool _closing = false;
  String? _photoErrorMessage;
  final _imagePicker = ImagePicker();
  final List<String> _existingImages = [];
  final List<XFile> _selectedImages = [];

  int get _photoCount => _existingImages.length + _selectedImages.length;

  @override
  void initState() {
    super.initState();
    _existingImages.addAll(widget.original?.images ?? const []);
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

  Future<void> _pickImages() async {
    if (_isPickingImages ||
        _submitted ||
        _closing ||
        context.read<RoomBloc>().state.saving ||
        _photoCount >= 10) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isPickingImages = true;
      _photoErrorMessage = null;
    });

    try {
      final photos = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (!mounted) return;

      setState(() {
        for (final photo in photos) {
          if (_selectedImages.any((item) => item.path == photo.path)) {
            continue;
          }
          if (_photoCount >= 10) {
            _photoErrorMessage = 'You can add up to 10 photos per room type.';
            break;
          }
          _selectedImages.add(photo);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoErrorMessage = 'Could not open photos. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  Widget _photoError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _photoPreview({
    required Widget image,
    required VoidCallback? onRemove,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 100.r,
      height: 100.r,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12.r), child: image),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: 'Remove photo',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.onSurface,
              ),
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RoomBloc, RoomState>(
    listener: (context, state) {
      if (state.actionSucceeded && _submitted) {
        setState(() {
          _submitted = false;
          _closing = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).pop();
        });
      }
      if (state.error != null) setState(() => _submitted = false);
    },
    builder: (context, state) {
      final busy = _submitted || state.saving || _isPickingImages || _closing;
      return PopScope(
        canPop: _closing || !busy,
        child: AlertDialog(
          title: Text(
            '${widget.original == null ? 'Add' : 'Edit'} ${widget.type.label} rooms',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set the capacity, nightly price, and total number '
                    'of rooms for this category.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 20.h),

                  TextFormField(
                    controller: _capacity,
                    enabled: !busy,
                    readOnly: widget.type.fixedCapacity != null,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Maximum guests per room',
                      prefixIcon: const Icon(Icons.people_outline),
                      helperText: widget.type.fixedCapacity != null
                          ? '${widget.type.label} rooms have a fixed '
                                'capacity of ${widget.type.fixedCapacity}.'
                          : 'Enter between 1 and 4 guests.',
                    ),
                    validator: (value) {
                      final capacity = int.tryParse(value?.trim() ?? '');

                      return capacity == null || capacity < 1 || capacity > 4
                          ? 'Enter 1–4 guests.'
                          : null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  TextFormField(
                    controller: _price,
                    enabled: !busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Price per night',
                      hintText: 'Example: 8500',
                      suffixText: 'DZD',
                      prefixIcon: Icon(Icons.payments_outlined),
                      helperText: 'Price for one room for one night.',
                    ),
                    validator: (value) =>
                        RoomEntity.parsePrice(value ?? '') == null
                        ? 'Enter 0.01–1,000,000 DZD (up to 2 decimals).'
                        : null,
                  ),
                  SizedBox(height: 20.h),

                  TextFormField(
                    controller: _count,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Number of rooms',
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                      helperText:
                          'Total rooms in this category, '
                          'not availability for specific dates.',
                    ),
                    validator: (value) {
                      final count = int.tryParse(value?.trim() ?? '');

                      return count == null || count < 1 || count > 10000
                          ? 'Enter 1–10,000 rooms.'
                          : null;
                    },
                  ),

                  SizedBox(height: 24.h),
                  Text(
                    'Room photos (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '$_photoCount / 10 photos. Show this room type. '
                    'Changes are applied when you tap Save.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 12.h),
                  OutlinedButton.icon(
                    onPressed: busy || _photoCount >= 10 ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _isPickingImages ? 'Opening photos…' : 'Choose photos',
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (_photoCount == 0) const Text('No photos selected yet.'),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      for (final url in _existingImages)
                        _photoPreview(
                          image: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: _photoError,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                          onRemove: busy
                              ? null
                              : () {
                                  setState(() {
                                    _existingImages.remove(url);
                                    _photoErrorMessage = null;
                                  });
                                },
                        ),
                      for (final photo in _selectedImages)
                        _photoPreview(
                          image: Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                            errorBuilder: _photoError,
                          ),
                          onRemove: busy
                              ? null
                              : () {
                                  setState(() {
                                    _selectedImages.remove(photo);
                                    _photoErrorMessage = null;
                                  });
                                },
                        ),
                    ],
                  ),
                  if (_photoErrorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Text(
                        _photoErrorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  if (state.error != null)
                    Padding(
                      padding: EdgeInsets.only(top: 16.h),
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
                      FocusScope.of(context).unfocus();
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
                            images: List<String>.unmodifiable(_existingImages),
                          ),
                          original: widget.original,
                          photoPaths: _selectedImages
                              .map((photo) => photo.path)
                              .toList(),
                        ),
                      );
                    },
              child: Text(_submitted || state.saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      );
    },
  );
}
