import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/blocs/items/items_bloc.dart';
import 'package:frontend/blocs/items/items_event.dart';
import 'package:frontend/blocs/items/items_state.dart';
import 'package:frontend/screens/home/widgets/filter_chips.dart';
import 'package:frontend/screens/home/widgets/item_card.dart';
import 'package:frontend/screens/home/widgets/nearby_reports.dart';
import 'package:frontend/screens/home/widgets/quick_action_cards.dart';
import 'package:frontend/screens/home/widgets/top_app_bar.dart';
import 'package:frontend/widgets/error_widgets.dart';
import 'package:frontend/widgets/item_card_skeleton.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ItemsBloc>().add(LoadItems());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Action Cards - Report Lost / Report Found
                    const QuickActionCards(),
                    const SizedBox(height: 24),
                    const NearbyReports(),
                    const SizedBox(height: 20),
                    Text(
                      'Recent Reports',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse lost and found items near you',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilterChips(
                      selected: _selectedFilter,
                      onSelected: (val) =>
                          setState(() => _selectedFilter = val),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<ItemsBloc, ItemsState>(
              builder: (context, state) {
                if (state is ItemsLoading) {
                  // ✅ Use shimmer skeleton loaders instead of spinner
                  return const ItemCardSkeletonList(count: 3);
                }
                if (state is ItemsLoaded) {
                  final filteredItems = state.items.where((item) {
                    final sel = _selectedFilter;
                    if (sel == 'All') return true;
                    if (sel == 'Lost') return item.isLost == true;
                    if (sel == 'Found') return item.isLost == false;
                    // For other categories (Pets, Electronics, Documents) do a simple
                    // description keyword match as Item has no category field yet.
                    return item.description.toLowerCase().contains(
                      sel.toLowerCase(),
                    );
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        title: _selectedFilter == 'All'
                            ? 'No items yet'
                            : 'No $_selectedFilter items',
                        subtitle: 'Be the first to report a lost or found item',
                        icon: Icons.search_off,
                        action: ElevatedButton.icon(
                          onPressed: () => context.push('/report-lost'),
                          icon: const Icon(Icons.add),
                          label: const Text('Report Item'),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];
                      return ItemCard(item: item);
                    }, childCount: filteredItems.length),
                  );
                }
                if (state is ItemsError) {
                  return SliverToBoxAdapter(
                    child: ErrorStateWidget(
                      title: 'Failed to load items',
                      subtitle: 'Pull down to refresh and try again',
                      onRetry: () => context.read<ItemsBloc>().add(LoadItems()),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
