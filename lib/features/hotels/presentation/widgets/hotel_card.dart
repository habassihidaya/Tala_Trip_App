import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tala_trip_app/core/constants/app_colors.dart';

class HotelCard extends StatelessWidget {
  final String name;
  final String wilaya;
  final String status;
  final VoidCallback? onTap;
  final String? imageUrl;
  final bool _isGrid;

  const HotelCard({
    super.key,
    required this.name,
    required this.wilaya,
    required this.status,
    this.imageUrl,
    this.onTap,
  }) : _isGrid = false;

  const HotelCard.grid({
    super.key,
    required this.name,
    required this.wilaya,
    this.imageUrl,
    this.onTap,
  }) : status = '',
       _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (!_isGrid) {
      return Card(
        child: ListTile(
          leading: SizedBox.square(
            dimension: 48.r,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: url == null || url.isEmpty
                  ? const _HotelPhotoFallback()
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return ColoredBox(
                          color: AppColors.infoSurface,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const _HotelPhotoFallback(),
                    ),
            ),
          ),
          title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('$wilaya • $status'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: url == null || url.isEmpty
                  ? const _HotelPhotoFallback()
                  : Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return ColoredBox(
                          color: AppColors.infoSurface,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 22.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const _HotelPhotoFallback(),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16.r,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          wilaya,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelPhotoFallback extends StatelessWidget {
  const _HotelPhotoFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.infoSurface,
      child: Center(
        child: Icon(Icons.hotel_outlined, size: 36.r, color: AppColors.primary),
      ),
    );
  }
}
