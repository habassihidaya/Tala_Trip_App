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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      appBar: AppBar(
        title: const Text('My hotels'),
        actions: [
          BlocBuilder<HotelBloc, HotelState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Refresh',
                onPressed: state is HotelLoadingState
                    ? null
                    : () => _reload(context),
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
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
                if (state is HotelInitialState || state is HotelLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is HotelErrorState) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () => _reload(context),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is HotelsEmptyState) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.r),
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
                  );
                }

                if (state is HotelsLoadedState) {
                  return ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                    itemCount: state.hotels.length,
                    itemBuilder: (context, index) {
                      final hotel = state.hotels[index];

                      return HotelCard(
                        key: ValueKey(hotel.id),
                        name: hotel.name,
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
                                content: Text('Hotel submitted for review.'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
