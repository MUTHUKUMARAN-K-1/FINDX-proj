import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/blocs/items/items_bloc.dart';
import 'package:frontend/blocs/items/items_state.dart';
import 'package:frontend/models/item.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Lost',
    'Found',
    'People',
    'Electronics',
    'Pets',
    'Documents',
    'Jewelry',
    'Bags & Wallets',
    'Keys',
    'Clothing',
    'Glasses & Eyewear',
    'Watches',
    'Headphones & Earbuds',
    'Laptops & Tablets',
    'Phones',
    'Cameras',
    'Sports Equipment',
    'Books & Stationery',
    'Toys',
    'Medical Items',
    'Umbrellas',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> _filterItems(List<Item> items) {
    return items.where((item) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description = item.description.toLowerCase();
        final category = (item.category ?? '').toLowerCase();
        final place = (item.placeName ?? '').toLowerCase();

        // Check if any tag matches the query
        bool tagMatch = false;
        if (item.tags != null) {
          tagMatch = item.tags!.any((tag) => tag.toLowerCase().contains(query));
        }

        if (!description.contains(query) &&
            !category.contains(query) &&
            !place.contains(query) &&
            !tagMatch) {
          return false;
        }
      }

      // Filter by category
      if (_selectedCategory != 'All') {
        if (_selectedCategory == 'Lost' && !item.isLost) return false;
        if (_selectedCategory == 'Found' && item.isLost) return false;
        if (_selectedCategory != 'Lost' && _selectedCategory != 'Found') {
          final category = (item.category ?? '').toLowerCase();
          if (category != _selectedCategory.toLowerCase()) return false;
        }
      }

      return true;
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'people':
        return Icons.person;
      case 'pets':
        return Icons.pets;
      case 'electronics':
        return Icons.phone_iphone;
      case 'documents':
        return Icons.description;
      case 'keys':
        return Icons.vpn_key;
      case 'jewelry':
        return Icons.diamond;
      case 'bags & wallets':
        return Icons.wallet;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'people':
        return Colors.blue;
      case 'pets':
        return Colors.orange;
      case 'electronics':
        return Colors.purple;
      case 'documents':
        return Colors.teal;
      case 'keys':
        return Colors.amber;
      case 'jewelry':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 170,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search lost or found items...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Results Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.1),
                          colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _searchQuery.isNotEmpty
                          ? Icons.search
                          : Icons.trending_up,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Results for "$_searchQuery"'
                        : 'All Items',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Results from Firebase
          BlocBuilder<ItemsBloc, ItemsState>(
            builder: (context, state) {
              if (state is ItemsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is ItemsError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading items',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ItemsLoaded) {
                final filteredItems = _filterItems(state.items);

                if (filteredItems.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search or category',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredItems[index];
                    final isLost = item.isLost;
                    final category = item.category ?? 'Other';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              context.push('/item/${item.id}', extra: item),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon Container
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      category,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: item.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          child: Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              _getCategoryIcon(category),
                                              color: _getCategoryColor(
                                                category,
                                              ),
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          _getCategoryIcon(category),
                                          color: _getCategoryColor(category),
                                          size: 28,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLost
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isLost ? 'LOST' : 'FOUND',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isLost
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            timeago.format(item.timestamp),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description.split('\n').first,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.placeName?.isNotEmpty == true
                                                  ? item.placeName!
                                                  : 'Near ${item.latitude.toStringAsFixed(2)}°, ${item.longitude.toStringAsFixed(2)}°',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: filteredItems.length),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
