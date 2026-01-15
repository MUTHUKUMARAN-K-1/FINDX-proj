import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/blocs/auth/auth_bloc.dart';
import 'package:frontend/blocs/items/items_bloc.dart';
import 'package:frontend/blocs/items/items_event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/utils/env_config.dart';
import 'package:frontend/widgets/ai_matches_widget.dart';
import 'package:frontend/widgets/item_status_dialog.dart';
import 'package:frontend/widgets/police_report_dialog.dart';
import 'package:frontend/widgets/share_poster_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ItemDetailsScreen extends StatelessWidget {
  final Item? item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Not Found')),
        body: const Center(
          child: Text('The requested item could not be found.'),
        ),
      );
    }

    return ItemDetailsView(item: item!);
  }
}

class ItemDetailsView extends StatefulWidget {
  final Item item;

  const ItemDetailsView({super.key, required this.item});

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  final ChatService _chatService = ChatService();
  bool _isContactLoading = false;

  void _openMaps() {
    // Navigate to in-app heatmap centered on this item's location
    context.push(
      '/heatmap?lat=${widget.item.latitude}&lng=${widget.item.longitude}',
    );
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ItemsBloc>().add(DeleteItem(widget.item.id));
              context.go('/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _contactOwner() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to contact the owner'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (widget.item.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'This is an older report without owner info. Try the contact details if available.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Check if user is trying to contact themselves
    if (widget.item.userId == authState.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You are the owner of this item!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Got it',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    setState(() => _isContactLoading = true);

    try {
      // Fetch owner's name from Firestore
      String ownerName = 'Item Owner';
      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.item.userId)
            .get();
        if (ownerDoc.exists) {
          final ownerData = ownerDoc.data();
          ownerName =
              ownerData?['displayName'] ?? ownerData?['name'] ?? 'Item Owner';
        }
      } catch (_) {
        // Use default name if fetch fails
      }

      final chatId = await _chatService.getOrCreateChat(
        userId1: authState.uid,
        userName1: authState.displayName ?? 'Anonymous',
        userId2: widget.item.userId!,
        userName2: ownerName,
        itemId: widget.item.id,
        itemTitle: widget.item.description.contains('|||')
            ? widget.item.description.split('|||').first
            : widget.item.description.split('\n').first,
      );

      if (mounted) {
        context.push('/chat-details/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }

    if (mounted) {
      setState(() => _isContactLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final isLost = item.isLost;
    final authState = context.read<AuthBloc>().state;
    final isOwner = authState is Authenticated && authState.uid == item.userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            actions: [
              if (isOwner)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteItem,
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    showSharePosterSheet(context, item);
                  },
                ),
              ),
              // Police Report button
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.local_police, color: Colors.white),
                  onPressed: () {
                    showPoliceReportDialog(context, item);
                  },
                  tooltip: 'Report to Police',
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 64,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isLost ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isLost ? Colors.red : Colors.green)
                                .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLost ? Icons.search : Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isLost ? 'LOST' : 'FOUND',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - parse from description using ||| separator
                    Text(
                      item.description.contains('|||')
                          ? item.description.split('|||').first
                          : item.description.split('\n').first,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category & Time
                    Row(
                      children: [
                        if (item.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category!,
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(item.timestamp),
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Tags Section
                    if (item.tags != null && item.tags!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.tags!
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Description Section
                    _buildSection(
                      title: 'Description',
                      icon: Icons.description,
                      child: Text(
                        item.description.contains('|||')
                            ? item.description.split('|||').last
                            : item.description,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Section
                    _buildSection(
                      title: 'Location',
                      icon: Icons.location_on,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Area name with home icon
                          if (item.placeName?.isNotEmpty == true) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.home,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🏠 Area: ${item.placeName!}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Coordinates
                          Row(
                            children: [
                              Icon(
                                Icons.public,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🌐 Coordinates: ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Map Preview
                          GestureDetector(
                            onTap: _openMaps,
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://maps.googleapis.com/maps/api/staticmap?center=${item.latitude},${item.longitude}&zoom=15&size=600x300&markers=color:red%7C${item.latitude},${item.longitude}&key=${EnvConfig.googleMapsApiKey}',
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.map,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Open in Maps',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔥 AI MATCHING SECTION
                    AIMatchesWidget(item: item),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isOwner) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isContactLoading ? null : _contactOwner,
                    icon: _isContactLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isLost ? Icons.chat_bubble : Icons.flag),
                    label: Text(isLost ? 'Contact Owner' : 'Claim Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLost
                          ? colorScheme.primary
                          : const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Edit functionality
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Item'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showItemStatusDialog(
                        context,
                        item,
                        onUpdate: (status, note, proof) {
                          // Refresh the item list after status update
                          context.read<ItemsBloc>().add(LoadItems());
                        },
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(isLost ? 'Mark Found' : 'Mark Returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
