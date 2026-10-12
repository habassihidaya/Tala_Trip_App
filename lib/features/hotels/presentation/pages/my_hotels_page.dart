import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:tala_trip_app/core/di/injection_container.dart';
import 'package:tala_trip_app/core/widgets/app_search_field.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_bloc.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_event.dart';
import 'package:tala_trip_app/features/hotels/presentation/bloc/hotel_state.dart';
import 'package:tala_trip_app/features/hotels/presentation/widgets/hotel_card.dart';

class MyHotelsPage extends StatelessWidget {
  const MyHotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HotelBloc>(
      create: (_) => getIt<HotelBloc>()..add(GetMyHotelsEvent()),
      child: const _MyHotelsView(),
    );
  }
}

class _MyHotelsView extends StatefulWidget {
  const _MyHotelsView();

  @override
  State<_MyHotelsView> createState() => _MyHotelsViewState();
}

class _MyHotelsViewState extends State<_MyHotelsView> {
  final _searchController = TextEditingController();

  bool get _hasSearch => _searchController.text.trim().isNotEmpty;

  void _searchHotels(String query) {
    setState(() {});

    context.read<HotelBloc>().add(SearchHotelsEvent(query: query));
  }

  void _clearSearch() {
    _searchController.clear();
    _searchHotels('');
  }

  void _reload(BuildContext context) {
    context.read<HotelBloc>().add(GetMyHotelsEvent());
  }

  Future<void> _refreshHotels() async {
    final bloc = context.read<HotelBloc>();

    if (bloc.isClosed || bloc.state is HotelLoadingState) return;

    // Subscribe before requesting the reload.
    // Ignore search results emitted before loading starts.
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

    bloc.add(GetMyHotelsEvent());

    await refreshFinished;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My hotels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/owner/hotels/add');

          if (!context.mounted) return;

          if (created == true) {
            _reload(context);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Hotel draft saved.')));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add hotel'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: AppSearchField(
              controller: _searchController,
              onChanged: _searchHotels,
              hintText: 'Search my hotels…',
            ),
          ),
          Expanded(
            child: BlocBuilder<HotelBloc, HotelState>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: _refreshHotels,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      if (state is HotelInitialState ||
                          state is HotelLoadingState)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is HotelErrorState)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                24.h,
                                24.w,
                                100.h,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.message,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16.h),
                                  ElevatedButton(
                                    onPressed: _refreshHotels,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (state is HotelsEmptyState)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                24.h,
                                24.w,
                                100.h,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _hasSearch
                                        ? 'No hotels match your search.'
                                        : 'You haven’t added a hotel yet.',
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_hasSearch) ...[
                                    SizedBox(height: 12.h),
                                    OutlinedButton(
                                      onPressed: _clearSearch,
                                      child: const Text('Clear search'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (state is HotelsLoadedState)
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final hotel = state.hotels[index];

                              return HotelCard(
                                key: ValueKey(hotel.id),
                                name: hotel.name,
                                imageUrl: hotel.images.isEmpty
                                    ? null
                                    : hotel.images.first,
                                wilaya: hotel.wilaya,
                                status: hotel.status.name,

                                onTap: () async {
                                  final submitted = await context.push<bool>(
                                    '/owner/hotels/'
                                    '${Uri.encodeComponent(hotel.id)}',
                                  );

                                  if (!context.mounted) return;

                                  _reload(context);

                                  if (submitted == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Hotel submitted for review.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }, childCount: state.hotels.length),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
