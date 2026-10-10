import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.type.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Up to ${room.capacity} guest'
              '${room.capacity == 1 ? '' : 's'} per room',
            ),
            Text('${room.priceText} DZD / night'),

            if (showInventory)
              Text('${room.totalRooms} rooms in this category'),

            if (onBook != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onBook,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book this room'),
                ),
              ),
            ],

            if (canEdit)
              Wrap(
                spacing: 12,
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
        ),
      ),
    );
  }
}
