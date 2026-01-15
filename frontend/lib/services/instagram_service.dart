import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for auto-posting lost items to Instagram
class InstagramService {
  static final InstagramService _instance = InstagramService._internal();
  factory InstagramService() => _instance;
  InstagramService._internal();

  // Backend URL - Render production deployment
  static const String _backendUrl = 'https://findx-instagram.onrender.com';

  /// Post a lost item to Instagram
  /// Returns true if successful, false otherwise
  Future<bool> postLostItem({
    required String imageUrl,
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? tags,
  }) async {
    try {
      // Create Instagram caption
      final caption = _createCaption(
        title: title,
        description: description,
        location: location,
        latitude: latitude,
        longitude: longitude,
        category: category,
        tags: tags,
      );

      print('📸 Posting to Instagram...');
      print('   Image: ${imageUrl.substring(0, 50)}...');
      print('   Caption: ${caption.substring(0, 100)}...');

      final response = await http.post(
        Uri.parse('$_backendUrl/api/post'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_url': imageUrl,
          'caption': caption,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Instagram post successful! Media ID: ${data['media_id']}');
        return true;
      } else {
        print(
          '❌ Instagram post failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Instagram post error: $e');
      return false;
    }
  }

  /// Create a formatted caption for Instagram with full location details
  String _createCaption({
    required String title,
    required String description,
    required String location,
    double? latitude,
    double? longitude,
    String? category,
    List<String>? tags,
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('🚨 LOST ITEM ALERT 🚨');
    buffer.writeln();

    // Title
    buffer.writeln('📦 $title');
    buffer.writeln();

    // Description
    if (description.isNotEmpty) {
      buffer.writeln('📝 $description');
      buffer.writeln();
    }

    // Category
    if (category != null && category.isNotEmpty) {
      buffer.writeln('🏷️ Category: $category');
      buffer.writeln();
    }

    // Location Section
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📍 LOCATION DETAILS');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');

    // Street/Area name
    if (location.isNotEmpty) {
      buffer.writeln('🏠 Area: $location');
    }

    // Coordinates
    if (latitude != null && longitude != null) {
      buffer.writeln(
        '🌐 Coordinates: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      );
      buffer.writeln();
      // Google Maps link
      buffer.writeln('🗺️ View on Maps:');
      buffer.writeln('https://maps.google.com/?q=$latitude,$longitude');
    }
    buffer.writeln();

    // Call to action
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '👀 If you found this item, please contact us through the FindX app!',
    );
    buffer.writeln();

    // Hashtags
    buffer.write('#FindX #LostAndFound #LostItem #HelpFind');
    if (location.isNotEmpty) {
      // Extract city/area for hashtag
      final parts = location.split(',');
      for (final part in parts.take(2)) {
        final cleanTag = part
            .trim()
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (cleanTag.isNotEmpty && cleanTag.length > 2) {
          buffer.write(' #$cleanTag');
        }
      }
    }
    if (category != null && category.isNotEmpty) {
      final cleanCategory = category.replaceAll(' ', '').replaceAll('&', '');
      buffer.write(' #$cleanCategory');
    }
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags.take(5)) {
        final cleanTag = tag
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (cleanTag.isNotEmpty && cleanTag.length > 2) {
          buffer.write(' #$cleanTag');
        }
      }
    }

    return buffer.toString();
  }
}
