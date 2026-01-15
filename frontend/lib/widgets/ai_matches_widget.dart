import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/ai_matching_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Widget that displays AI-powered potential matches for an item
class AIMatchesWidget extends StatefulWidget {
  final Item item;

  const AIMatchesWidget({super.key, required this.item});

  @override
  State<AIMatchesWidget> createState() => _AIMatchesWidgetState();
}

class _AIMatchesWidgetState extends State<AIMatchesWidget> {
  List<MatchResult>? _matches;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _findMatches();
  }

  Future<void> _findMatches() async {
    try {
      final service = AIMatchingService();
      List<MatchResult> matches;

      if (widget.item.isLost) {
        // For lost items, find matching found items
        matches = await service.findMatchesForLostItem(widget.item);
      } else {
        // For found items, find matching lost items
        matches = await service.findMatchesForFoundItem(widget.item);
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchType = widget.item.isLost ? 'Found Items' : 'Lost Items';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 AI Matching',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Potential matching $matchType',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (_isLoading)
            _buildLoadingState(isDark)
          else if (_error != null)
            _buildErrorState()
          else if (_matches == null || _matches!.isEmpty)
            _buildNoMatchesState(matchType)
          else
            _buildMatchesList(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Column(
        children: List.generate(
          2,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Unable to find matches. Please try again later.'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesState(String matchType) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No Matching $matchType Found',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll notify you when potential matches are found',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        // Matches found banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF22C55E).withOpacity(0.15),
                const Color(0xFF10B981).withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 ${_matches!.length} Potential Match${_matches!.length > 1 ? 'es' : ''} Found!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'AI analyzed and found similar items',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF166534).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Match cards
        ...(_matches!.map(
          (match) => _buildMatchCard(match, colorScheme, isDark),
        )),
      ],
    );
  }

  Widget _buildMatchCard(
    MatchResult match,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    // Parse title
    String title = '';
    if (match.foundItem.description.contains('|||')) {
      title = match.foundItem.description.split('|||').first.trim();
    } else {
      title = match.foundItem.description.split('\n').first;
    }

    // Confidence color
    Color confidenceColor;
    String confidenceLabel;
    if (match.confidenceScore >= 80) {
      confidenceColor = const Color(0xFF22C55E);
      confidenceLabel = 'High Match';
    } else if (match.confidenceScore >= 50) {
      confidenceColor = const Color(0xFFF59E0B);
      confidenceLabel = 'Medium Match';
    } else {
      confidenceColor = const Color(0xFF6366F1);
      confidenceLabel = 'Possible Match';
    }

    return GestureDetector(
      onTap: () =>
          context.push('/item/${match.foundItem.id}', extra: match.foundItem),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: confidenceColor.withOpacity(0.3), width: 2),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: confidenceColor.withOpacity(0.1),
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
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: match.foundItem.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: match.foundItem.imageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Confidence badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: confidenceColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: confidenceColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: confidenceColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${match.confidenceScore.toInt()}% $confidenceLabel',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: confidenceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              match.foundItem.placeName ?? 'Unknown location',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
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
                // Arrow
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
            // Match reason
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.matchReason,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Matching features
            if (match.matchingFeatures.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: match.matchingFeatures
                    .map(
                      (feature) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '✓ $feature',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            // Contact Owner button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to chat with item owner
                  context.push('/chat/${match.foundItem.userId}');
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  'Contact ${widget.item.isLost ? "Finder" : "Owner"}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confidenceColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
