import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/room_entity.dart';

class RoomCard extends StatelessWidget {
  final RoomEntity room;
  final bool showInventory;
  final bool canEdit;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBook;

  const RoomCard({
    super.key,
    required this.room,
    required this.showInventory,
    required this.canEdit,
    required this.busy,
    this.onEdit,
    this.onDelete,
    this.onBook,
  });

  void _openPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return Dialog.fullscreen(
          backgroundColor: colors.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('Photo unavailable'));
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  minimum: EdgeInsets.all(8.r),
                  child: IconButton.filledTonal(
                    tooltip: 'Close photo',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (room.images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: PageView.builder(
                    // Reset the gallery if its photos change after an edit.
                    key: ValueKey(room.images.join('|')),
                    itemCount: room.images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openPhoto(context, room.images[index]),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              room.images[index],
                              fit: BoxFit.cover,
                              semanticLabel:
                                  '${room.type.label} room photo ${index + 1}',
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return ColoredBox(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return ColoredBox(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12.r),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          SizedBox(height: 8.h),
                                          const Text(
                                            'Photo unavailable',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (room.images.length > 1)
                              Positioned(
                                right: 8.w,
                                bottom: 8.h,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 6.h,
                                    ),
                                    child: Text(
                                      '${index + 1} / ${room.images.length}',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (room.images.length > 1) ...[
                SizedBox(height: 8.h),
                Text(
                  'Swipe to see more photos',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 16.h),
            ],
            Text(room.type.label, style: theme.textTheme.titleLarge),
            SizedBox(height: 12.h),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 20.r,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Up to ${room.capacity} guest'
                    '${room.capacity == 1 ? '' : 's'} per room',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Text(
              '${room.priceText} DZD / night',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (showInventory) ...[
              SizedBox(height: 12.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 20.r,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${room.totalRooms} rooms in this category',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],

            if (onBook != null) ...[
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: busy ? null : onBook,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text(
                  'Book this room',
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            if (canEdit) ...[
              SizedBox(height: 16.h),
              const Divider(height: 1),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  TextButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
