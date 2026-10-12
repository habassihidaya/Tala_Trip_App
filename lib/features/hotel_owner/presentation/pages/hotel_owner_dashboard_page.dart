import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/constants/app_colors.dart';
import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/features/auth/domain/entities/user_role.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:tala_trip_app/features/auth/presentation/blocs/auth_state.dart';
import 'package:tala_trip_app/features/bookings/domain/entities/booking_entity.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_status.dart';
import 'package:tala_trip_app/features/hotels/presentation/widgets/hotel_card.dart';

import '../bloc/owner_dashboard_bloc.dart';
import '../bloc/owner_dashboard_event.dart';
import '../bloc/owner_dashboard_state.dart';

class HotelOwnerDashboardPage extends StatelessWidget {
  const HotelOwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated ||
            state.user.role != UserRole.hotelOwner) {
          return const SizedBox.shrink();
        }

        return BlocProvider<OwnerDashboardBloc>(
          key: ValueKey(state.user.id),
          create: (_) =>
              getIt<OwnerDashboardBloc>()..add(const OwnerDashboardRequested()),
          child: _OwnerDashboardView(ownerName: state.user.username),
        );
      },
    );
  }
}

class _OwnerDashboardView extends StatefulWidget {
  final String ownerName;

  const _OwnerDashboardView({required this.ownerName});

  @override
  State<_OwnerDashboardView> createState() => _OwnerDashboardViewState();
}

class _OwnerDashboardViewState extends State<_OwnerDashboardView>
    with WidgetsBindingObserver {
  GoRouter? _router;
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final router = GoRouter.of(context);

    if (identical(router, _router)) return;

    _router?.routeInformationProvider.removeListener(_onRouteChanged);

    _router = router;
    _lastPath = router.routeInformationProvider.value.uri.path;

    router.routeInformationProvider.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final path = _router?.routeInformationProvider.value.uri.path;
    final returnedToDashboard = path == '/owner' && _lastPath != '/owner';

    _lastPath = path;

    if (returnedToDashboard) {
      _scheduleReload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _router?.routeInformationProvider.value.uri.path == '/owner') {
      _scheduleReload();
    }
  }

  void _scheduleReload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bloc = context.read<OwnerDashboardBloc>();

      if (!bloc.isClosed && bloc.state is! OwnerDashboardLoading) {
        bloc.add(const OwnerDashboardRequested());
      }
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<OwnerDashboardBloc>();

    if (bloc.isClosed || bloc.state is OwnerDashboardLoading) return;

    final finished = bloc.stream
        .where(
          (state) =>
              state is OwnerDashboardLoaded || state is OwnerDashboardFailure,
        )
        .take(1)
        .drain<void>();

    bloc.add(const OwnerDashboardRequested());

    await finished;
  }

  Future<void> _openHotel(String hotelId) async {
    await context.push('/owner/hotels/${Uri.encodeComponent(hotelId)}');

    if (!mounted) return;

    _scheduleReload();
  }

  String _hotelStatusLabel(HotelStatus status) {
    return switch (status) {
      HotelStatus.draft => 'Draft',
      HotelStatus.pending => 'Pending review',
      HotelStatus.approved => 'Approved',
      HotelStatus.rejected => 'Rejected',
    };
  }

  String _checkInLabel(BookingEntity booking) {
    // Convert the check-in instant to Algeria's UTC+1 calendar date.
    final date = booking.checkInStartsAt.toUtc().add(const Duration(hours: 1));

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ownerDashboardBackground,
      appBar: AppBar(
        title: const Text('Owner dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: BlocBuilder<OwnerDashboardBloc, OwnerDashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state is OwnerDashboardInitial ||
                      state is OwnerDashboardLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is OwnerDashboardFailure)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                size: 48.r,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 16.h),
                              Text(state.message, textAlign: TextAlign.center),
                              SizedBox(height: 16.h),
                              FilledButton(
                                onPressed: _refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state is OwnerDashboardLoaded)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                      sliver: SliverToBoxAdapter(
                        child: _buildDashboard(context, state),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, OwnerDashboardLoaded state) {
    final theme = Theme.of(context);
    final pendingPreview = state.pendingRequests.take(3);
    final hotelPreview = state.hotels.take(3);

    // Count hotels awaiting approval from the already-loaded hotel list.
    final pendingHotelCount = state.hotels
        .where((hotel) => hotel.status == HotelStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome, ${widget.ownerName}',
          style: theme.textTheme.headlineMedium,
        ),
        SizedBox(height: 8.h),
        Text(
          'Manage your hotels and booking requests.',
          style: theme.textTheme.bodyLarge,
        ),

        SizedBox(height: 24.h),

        // First row of the 2 × 2 statistics grid.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.apartment_outlined,
                  label: 'My hotels',
                  value: state.hotelCount,
                  accentColor: AppColors.crystalLagoon,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending booking requests',
                  value: state.pendingRequestCount,
                  accentColor: AppColors.lotusPink,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // Second row of the statistics grid.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Hotels awaiting approval',
                  value: pendingHotelCount,
                  accentColor: AppColors.waterLily,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.event_available_outlined,
                  label: 'Upcoming confirmed bookings',
                  value: state.upcomingBookingCount,
                  accentColor: AppColors.mintBloom,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 28.h),
        _SectionHeading(
          title: 'Pending requests',
          actionLabel: 'View all requests',
          onPressed: () => context.go('/owner/bookings'),
        ),
        SizedBox(height: 8.h),

        if (state.pendingRequests.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Text('No booking requests need a response right now.'),
          )
        else
          for (final booking in pendingPreview)
            Card(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      booking.travelerName,
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 6.h),
                    Text(booking.hotelName),
                    SizedBox(height: 6.h),
                    Text(
                      '${booking.roomType.label} · '
                      '${booking.guests} guest(s) · '
                      '${booking.nights} night(s)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Check-in: ${_checkInLabel(booking)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

        SizedBox(height: 24.h),
        _SectionHeading(
          title: 'My hotels',
          actionLabel: 'View all hotels',
          onPressed: () => context.go('/owner/hotels'),
        ),
        SizedBox(height: 8.h),

        if (state.hotels.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Text(
              'You haven’t added a hotel yet. '
              'Tap the + button below to create your first draft.',
            ),
          )
        else
          for (final hotel in hotelPreview)
            HotelCard(
              key: ValueKey(hotel.id),
              name: hotel.name,
              wilaya: hotel.wilaya,
              status: _hotelStatusLabel(hotel.status),
              imageUrl: hotel.images.isEmpty ? null : hotel.images.first,
              onTap: () => _openHotel(hotel.id),
            ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accentColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.22),
      AppColors.surface,
    );

    final iconColor = Color.lerp(accentColor, AppColors.textPrimary, 0.5)!;

    return Card(
      margin: EdgeInsets.zero,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, size: 22.r, color: iconColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$value',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 4.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}
