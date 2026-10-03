import 'package:flutter/material.dart';

class HotelCard extends StatelessWidget {
  final String name;
  final String wilaya;
  final String status;
  final VoidCallback? onTap;

  const HotelCard({
    super.key,
    required this.name,
    required this.wilaya,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hotel),
        title: Text(name),
        subtitle: Text('$wilaya • $status'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}