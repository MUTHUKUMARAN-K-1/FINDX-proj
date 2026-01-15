import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/utils/env_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Result of AI matching between lost and found items
class MatchResult {
  final Item foundItem;
  final double confidenceScore;
  final String matchReason;
  final List<String> matchingFeatures;

  MatchResult({
    required this.foundItem,
    required this.confidenceScore,
    required this.matchReason,
    required this.matchingFeatures,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json, Item item) {
    return MatchResult(
      foundItem: item,
      confidenceScore: (json['confidence'] ?? 0).toDouble(),
      matchReason: json['reason'] ?? 'Potential match based on description',
      matchingFeatures: List<String>.from(json['matchingFeatures'] ?? []),
    );
  }
}

/// Service for AI-powered matching of lost and found items
class AIMatchingService {
  static final AIMatchingService _instance = AIMatchingService._internal();
  factory AIMatchingService() => _instance;
  AIMatchingService._internal();

  static String get _apiKey => EnvConfig.geminiApiKey;

  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    return _model!;
  }

  /// Find potential matches for a lost item from all found items
  Future<List<MatchResult>> findMatchesForLostItem(Item lostItem) async {
    try {
      print('🔍 Finding AI matches for lost item: ${lostItem.id}');

      // Get all found items from Firestore
      final foundItemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('isLost', isEqualTo: false)
          .where('status', isEqualTo: 'active')
          .get();

      if (foundItemsSnapshot.docs.isEmpty) {
        print('📭 No found items to match against');
        return [];
      }

      final foundItems = foundItemsSnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();

      print('📦 Found ${foundItems.length} found items to compare');

      // Use Gemini to analyze and rank matches
      final matches = await _analyzeMatchesWithGemini(lostItem, foundItems);

      // Sort by confidence score
      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      // Return top matches with score > 30%
      return matches.where((m) => m.confidenceScore >= 30).take(5).toList();
    } catch (e) {
      print('❌ AI Matching error: $e');
      return [];
    }
  }

  /// Find potential matches for a found item from all lost items
  Future<List<MatchResult>> findMatchesForFoundItem(Item foundItem) async {
    try {
      print('🔍 Finding AI matches for found item: ${foundItem.id}');

      // Get all lost items from Firestore
      final lostItemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('isLost', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      if (lostItemsSnapshot.docs.isEmpty) {
        print('📭 No lost items to match against');
        return [];
      }

      final lostItems = lostItemsSnapshot.docs
          .map((doc) => Item.fromFirestore(doc))
          .toList();

      print('📦 Found ${lostItems.length} lost items to compare');

      // Use Gemini to analyze and rank matches
      final matches = await _analyzeMatchesWithGemini(foundItem, lostItems);

      // Sort by confidence score
      matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      // Return top matches with score > 30%
      return matches.where((m) => m.confidenceScore >= 30).take(5).toList();
    } catch (e) {
      print('❌ AI Matching error: $e');
      return [];
    }
  }

  /// Use Gemini to analyze potential matches
  Future<List<MatchResult>> _analyzeMatchesWithGemini(
    Item sourceItem,
    List<Item> candidateItems,
  ) async {
    if (_apiKey.isEmpty) {
      print('⚠️ Gemini API key not configured');
      return _fallbackMatching(sourceItem, candidateItems);
    }

    final List<MatchResult> results = [];

    // Parse source item details
    String sourceTitle = '';
    String sourceDescription = '';
    if (sourceItem.description.contains('|||')) {
      final parts = sourceItem.description.split('|||');
      sourceTitle = parts.first.trim();
      sourceDescription = parts.length > 1 ? parts[1].trim() : '';
    } else {
      sourceTitle = sourceItem.description.split('\n').first;
      sourceDescription = sourceItem.description;
    }

    // Batch process candidates (max 10 at a time to avoid rate limits)
    final batches = <List<Item>>[];
    for (var i = 0; i < candidateItems.length; i += 10) {
      batches.add(
        candidateItems.sublist(
          i,
          i + 10 > candidateItems.length ? candidateItems.length : i + 10,
        ),
      );
    }

    for (final batch in batches) {
      try {
        // Build comparison prompt
        final candidateDescriptions = batch
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              String title = '';
              String desc = '';
              if (item.description.contains('|||')) {
                final parts = item.description.split('|||');
                title = parts.first.trim();
                desc = parts.length > 1 ? parts[1].trim() : '';
              } else {
                title = item.description.split('\n').first;
                desc = item.description;
              }
              return '''
Item ${entry.key + 1}:
- Title: $title
- Description: $desc
- Category: ${item.category ?? 'Unknown'}
- Location: ${item.placeName ?? 'Unknown'}
- Tags: ${item.tags?.join(', ') ?? 'None'}
''';
            })
            .join('\n');

        final prompt =
            '''
You are an AI assistant for a Lost & Found platform. Analyze if any of the following items could be a match for the source item.

SOURCE ITEM (${sourceItem.isLost ? 'LOST' : 'FOUND'}):
- Title: $sourceTitle
- Description: $sourceDescription
- Category: ${sourceItem.category ?? 'Unknown'}
- Location: ${sourceItem.placeName ?? 'Unknown'}
- Tags: ${sourceItem.tags?.join(', ') ?? 'None'}

CANDIDATE ITEMS TO COMPARE:
$candidateDescriptions

For each candidate item, provide a JSON response with:
- item_index: the item number (1-${batch.length})
- confidence: match confidence percentage (0-100)
- reason: brief explanation of why it could/couldn't be a match
- matching_features: list of features that match (e.g., ["color", "category", "brand"])

Only include items with confidence > 20%.

Respond ONLY with a valid JSON array like:
[
  {"item_index": 1, "confidence": 85, "reason": "Same brand and color electronics", "matching_features": ["brand", "color", "category"]},
  {"item_index": 3, "confidence": 45, "reason": "Similar category but different color", "matching_features": ["category"]}
]

If no matches found, respond with empty array: []
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final responseText = response.text ?? '[]';

        // Parse JSON response
        String jsonStr = responseText;
        if (jsonStr.contains('```json')) {
          jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
        } else if (jsonStr.contains('```')) {
          jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
        }

        final List<dynamic> matchData = json.decode(jsonStr);

        for (final match in matchData) {
          final itemIndex = (match['item_index'] ?? 1) - 1;
          if (itemIndex >= 0 && itemIndex < batch.length) {
            results.add(
              MatchResult(
                foundItem: batch[itemIndex],
                confidenceScore: (match['confidence'] ?? 0).toDouble(),
                matchReason: match['reason'] ?? 'AI detected similarity',
                matchingFeatures: List<String>.from(
                  match['matching_features'] ?? [],
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('⚠️ Batch matching error: $e');
        // Fallback to basic matching for this batch
        results.addAll(_fallbackMatching(sourceItem, batch));
      }
    }

    return results;
  }

  /// Fallback matching using keyword comparison when Gemini is unavailable
  List<MatchResult> _fallbackMatching(Item sourceItem, List<Item> candidates) {
    final List<MatchResult> results = [];

    final sourceWords = _extractKeywords(sourceItem);

    for (final candidate in candidates) {
      final candidateWords = _extractKeywords(candidate);

      // Calculate overlap
      final overlap = sourceWords.intersection(candidateWords);
      final score = sourceWords.isEmpty
          ? 0.0
          : (overlap.length / sourceWords.length) * 100;

      if (score >= 20) {
        results.add(
          MatchResult(
            foundItem: candidate,
            confidenceScore: score,
            matchReason: 'Matched keywords: ${overlap.join(", ")}',
            matchingFeatures: overlap.toList(),
          ),
        );
      }
    }

    return results;
  }

  /// Extract keywords from an item for basic matching
  Set<String> _extractKeywords(Item item) {
    final words = <String>{};

    // Add category
    if (item.category != null) {
      words.add(item.category!.toLowerCase());
    }

    // Add tags
    if (item.tags != null) {
      words.addAll(item.tags!.map((t) => t.toLowerCase()));
    }

    // Add description words (filter out common words)
    final commonWords = {
      'the',
      'a',
      'an',
      'is',
      'was',
      'are',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'shall',
      'can',
      'need',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'my',
      'your',
      'his',
      'her',
      'its',
      'our',
      'their',
      'this',
      'that',
      'these',
      'those',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
    };

    final descWords = item.description
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !commonWords.contains(w));

    words.addAll(descWords);

    return words;
  }
}
