import 'package:flutter/material.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_status.dart';

class BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final bool ownerView;
  final Widget? actions;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const BookingCard({
    super.key,
    required this.booking,
    required this.ownerView,
    this.actions,
    this.onCall,
    this.onWhatsApp,
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
              ownerView ? booking.travelerName : booking.hotelName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            _InfoLine(
              label: 'Room',
              value: booking.roomType.label,
            ),
            _InfoLine(
              label: 'Guests',
              value: '${booking.guests} guest(s)',
            ),
            _InfoLine(
              label: 'Stay',
              value:
                  '${_formatDate(booking.dates.checkInDate)} → '
                  '${_formatDate(booking.dates.checkOutDate)} '
                  '(${booking.nights} night(s))',
            ),
            _InfoLine(
              label: 'Total price',
              value:
                  '${_formatCentimes(booking.totalPriceInCentimes)} '
                  '${booking.currency}',
            ),
            _InfoLine(
              label: 'Request sent',
              value: _formatInstant(booking.createdAt),
            ),

            const SizedBox(height: 8),

            Chip(
              label: Text(_statusLabel(booking.status)),
              backgroundColor: _statusColor(
                context,
                booking.status,
              ),
            ),

            if (ownerView) ...[
              const SizedBox(height: 8),
               _InfoLine(
                label: 'Hotel',
                value: booking.hotelName,
              ),
              _InfoLine(
                label: 'Traveler phone',
                value: booking.travelerPhone,
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (onCall != null)
                    OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call'),
                    ),
                  if (onWhatsApp != null)
                    OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              _InfoLine(
                label: 'Hotel address',
                value: booking.hotelAddress,
              ),
            ],

            if (booking.rejectionReason != null &&
                booking.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoLine(
                label: 'Reason',
                value: booking.rejectionReason!,
              ),
            ],

            if (actions != null) ...[
              const Divider(height: 24),
              actions!,
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _formatInstant(DateTime instant) {
  final local = instant.toLocal();
  final date = _formatDate(local);
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$date at $hour:$minute';
}

String _formatCentimes(int value) {
  final dinars = value ~/ 100;
  final centimes = (value % 100).toString().padLeft(2, '0');

  return '$dinars.$centimes';
}

String _statusLabel(BookingStatus status) {
  final text = status.name;

  return text[0].toUpperCase() + text.substring(1);
}

Color _statusColor(
  BuildContext context,
  BookingStatus status,
) {
  final colors = Theme.of(context).colorScheme;

  return switch (status) {
    BookingStatus.pending => colors.secondaryContainer,
    BookingStatus.confirmed => colors.primaryContainer,
    BookingStatus.rejected => colors.errorContainer,
    BookingStatus.cancelled => colors.surfaceContainerHighest,
  };
}