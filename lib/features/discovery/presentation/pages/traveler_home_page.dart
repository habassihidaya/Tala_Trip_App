import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/constants/app_colors.dart';
import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/core/widgets/app_search_field.dart';
import 'package:tala_trip_app/features/favorites/presentation/widgets/traveler_hotel_card.dart';
import 'package:tala_trip_app/features/hotels/domain/entities/hotel_entity.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';

class TravelerHomePage extends StatelessWidget {
  const TravelerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocProvider<HotelBloc>(
          create: (_) => getIt<HotelBloc>()..add(GetApprovedHotelsEvent()),
          child: const _ApprovedHotels(),
        ),
      ),
    );
  }
}

class _ApprovedHotels extends StatefulWidget {
  const _ApprovedHotels();

  @override
  State<_ApprovedHotels> createState() => _ApprovedHotelsState();
}

class _ApprovedHotelsState extends State<_ApprovedHotels> {
  final _searchController = TextEditingController();

  String? _selectedWilaya;

  bool _hasSearch = false;

  String get _selectedWilayaLabel => _selectedWilaya ?? '';

  void _searchHotels(String query) {
    final hasSearch = query.trim().isNotEmpty;

    if (_hasSearch != hasSearch) {
      setState(() {
        _hasSearch = hasSearch;
      });
    }

    context.read<HotelBloc>().add(SearchHotelsEvent(query: query));
  }

  void _clearSearch() {
    _searchController.clear();
    _searchHotels('');
  }

  void _selectWilaya(String? wilaya) {
    if (_selectedWilaya == wilaya) return;

    setState(() {
      _selectedWilaya = wilaya;
    });

    context.read<HotelBloc>().add(FilterApprovedHotelsEvent(wilaya: wilaya));
  }

  void _reload() {
    context.read<HotelBloc>().add(GetApprovedHotelsEvent());
  }

  Future<void> _refreshHotels() async {
    final bloc = context.read<HotelBloc>();

    if (bloc.isClosed || bloc.state is HotelLoadingState) return;

    // Subscribe before requesting the reload.
    // Ignore filter results emitted before loading starts.
    final refreshFinished = bloc.stream
        .skipWhile((state) => state is! HotelLoadingState)
        .where(
          (state) =>
              state is HotelsLoadedState ||
              state is HotelsEmptyState ||
              state is HotelErrorState,
        )
        .take(1)
        .drain<void>();

    bloc.add(GetApprovedHotelsEvent());

    await refreshFinished;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final header = _HomeHeader(
      searchController: _searchController,
      onSearchChanged: _searchHotels,
    );

    return BlocBuilder<HotelBloc, HotelState>(
      builder: (context, state) {
        final loading =
            state is HotelInitialState || state is HotelLoadingState;

        final hotels = state is HotelsLoadedState
            ? state.hotels
            : const <HotelEntity>[];

        final canFilter =
            state is HotelsLoadedState || state is HotelsEmptyState;

        final title = _hasSearch
            ? (_selectedWilaya == null
                  ? 'Search results'
                  : 'Search results in $_selectedWilayaLabel')
            : (_selectedWilaya == null
                  ? 'Recommended stays'
                  : 'Hotels in $_selectedWilayaLabel');

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          displacement: 64.h,
          onRefresh: _refreshHotels,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverToBoxAdapter(
                child: _WilayaSection(
                  selectedWilaya: _selectedWilaya,
                  enabled: canFilter,
                  onSelected: _selectWilaya,
                ),
              ),

              // Results heading.
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Loading.
              if (loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.h),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                )
              // Error: keep the retry button.
              else if (state is HotelErrorState)
                SliverToBoxAdapter(
                  child: _HomeMessage(
                    icon: Icons.wifi_off_rounded,
                    message: state.message,
                    label: 'Try again',
                    onPressed: _refreshHotels,
                  ),
                )
              // Empty list or no matching results.
              else if (state is HotelsEmptyState ||
                  (state is HotelsLoadedState && hotels.isEmpty))
                SliverToBoxAdapter(
                  child: _HomeMessage(
                    icon: Icons.travel_explore_rounded,
                    message: _hasSearch
                        ? (_selectedWilaya == null
                              ? 'No hotels match your search.'
                              : 'No hotels match your search in '
                                    '$_selectedWilayaLabel.')
                        : (_selectedWilaya == null
                              ? 'No approved hotels are available yet.'
                              : 'No approved hotels in '
                                    '$_selectedWilayaLabel yet.'),
                    label: _hasSearch
                        ? 'Clear search'
                        : (_selectedWilaya != null ? 'Show all hotels' : null),
                    onPressed: _hasSearch
                        ? _clearSearch
                        : (_selectedWilaya != null
                              ? () => _selectWilaya(null)
                              : null),
                    hint: !_hasSearch && _selectedWilaya == null
                        ? 'Pull down to refresh.'
                        : null,
                  ),
                )
              // Hotel results.
              else if (state is HotelsLoadedState)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 28.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, rowIndex) {
                      final firstIndex = rowIndex * 2;
                      final secondIndex = firstIndex + 1;
                      final hasSecondHotel = secondIndex < hotels.length;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _hotelCard(hotels[firstIndex])),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: hasSecondHotel
                                    ? _hotelCard(hotels[secondIndex])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: (hotels.length + 1) ~/ 2),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _hotelCard(HotelEntity hotel) {
    return TravelerHotelCard(
      key: ValueKey(hotel.id),
      hotel: hotel,
      onTap: () async {
        await context.push('/traveler/hotels/${Uri.encodeComponent(hotel.id)}');

        if (!mounted) return;

        _reload();
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _HomeHeader({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.primaryLight),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withValues(alpha: 0.94),
                  AppColors.background.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1],
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 64.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'TALA ',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: 'TRIP',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(letterSpacing: 1.2),
              ),
              SizedBox(height: 20.h),
              Text(
                'Discover Algeria',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Find your perfect stay and explore\nbeautiful destinations.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 24.h),
              AppSearchField(
                controller: searchController,
                onChanged: onSearchChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WilayaSection extends StatelessWidget {
  final String? selectedWilaya;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  const _WilayaSection({
    required this.selectedWilaya,
    required this.enabled,
    required this.onSelected,
  });

  // Display label, stored value, asset name, fallback icon.
  static const _destinations = [
    ('Algiers', 'Algiers', 'algiers', Icons.location_city_rounded),
    ('Oran', 'Oran', 'oran', Icons.waves_rounded),
    ('Annaba', 'Annaba', 'annaba', Icons.account_balance_rounded),
    ('Béjaïa', 'Béjaïa', 'bejaia', Icons.landscape_rounded),
    ('Tipaza', 'Tipaza', 'tipaza', Icons.architecture_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Wrap(
              spacing: 12.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Explore by Wilaya',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (selectedWilaya != null)
                  TextButton(
                    onPressed: enabled ? () => onSelected(null) : null,
                    child: const Text('Show all'),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _destinations.length; i++) ...[
                  if (i > 0) SizedBox(width: 12.w),
                  _destination(
                    context,
                    label: _destinations[i].$1,
                    value: _destinations[i].$2,
                    assetName: _destinations[i].$3,
                    icon: _destinations[i].$4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _destination(
    BuildContext context, {
    required String label,
    required String value,
    required String assetName,
    required IconData icon,
  }) {
    final selected = selectedWilaya == value;

    return SizedBox(
      width: 94.w,
      child: Semantics(
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: enabled ? () => onSelected(value) : null,
            child: Padding(
              padding: EdgeInsets.all(3.r),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.asset(
                          'assets/images/wilaya_$assetName.jpg',
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: AppColors.infoSurface,
                            child: Center(
                              child: Icon(
                                icon,
                                size: 36.r,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? label;
  final VoidCallback? onPressed;
  final String? hint;

  const _HomeMessage({
    required this.icon,
    required this.message,
    this.label,
    this.onPressed,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
      child: Column(
        children: [
          Icon(icon, size: 36.r, color: AppColors.primary),
          SizedBox(height: 12.h),
          Text(message, textAlign: TextAlign.center),
          if (label != null && onPressed != null) ...[
            SizedBox(height: 12.h),
            OutlinedButton(onPressed: onPressed, child: Text(label!)),
          ],
          if (hint != null) ...[
            SizedBox(height: 12.h),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
