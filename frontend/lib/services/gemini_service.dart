import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/env_config.dart';

/// Result of image analysis from Gemini
class ImageAnalysisResult {
  final String title;
  final String description;
  final String suggestedCategory;
  final List<String> tags;
  final String? color;
  final String? brand;
  final String? condition;

  ImageAnalysisResult({
    required this.title,
    required this.description,
    required this.suggestedCategory,
    required this.tags,
    this.color,
    this.brand,
    this.condition,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      title: json['title'] ?? json['description'] ?? '',
      description: json['description'] ?? '',
      suggestedCategory: json['category'] ?? 'Other',
      tags: List<String>.from(json['tags'] ?? []),
      color: json['color'],
      brand: json['brand'],
      condition: json['condition'],
    );
  }
}

/// Service for Gemini AI image recognition and auto-tagging
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Use Gemini API key from environment config
  static String get _apiKey => EnvConfig.geminiApiKey;

  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    return _model!;
  }

  /// Analyze an image and extract tags, description, and category
  /// Uses Gemini as primary (Vision API fallback disabled - not enabled in project)
  Future<ImageAnalysisResult> analyzeImage(File imageFile) async {
    try {
      // Try Gemini
      return await _analyzeWithGemini(imageFile);
    } catch (e) {
      print('⚠️ Gemini analysis failed: $e');
      // Return default result if Gemini fails
      return ImageAnalysisResult(
        title: 'Unknown Item',
        description:
            'Unable to analyze image automatically. Please provide details manually.',
        suggestedCategory: 'Other',
        tags: [],
      );
    }
  }

  /// Analyze image using Gemini AI
  Future<ImageAnalysisResult> _analyzeWithGemini(File imageFile) async {
    print('🔍 Analyzing image with Gemini AI...');

    // Read image bytes
    final imageBytes = await imageFile.readAsBytes();

    // Determine image type
    final extension = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'gif') {
      mimeType = 'image/gif';
    } else if (extension == 'webp') {
      mimeType = 'image/webp';
    }

    // Create image part
    final imagePart = DataPart(mimeType, imageBytes);

    // Create prompt for structured analysis
    const prompt = '''
Analyze this image of a lost or found item. Provide a JSON response with the following structure:
{
  "title": "Short 3-5 word name of the item (e.g., 'Silver Samsung Laptop', 'Black Leather Wallet')",
  "description": "A detailed 2-3 sentence description including color, brand, condition, and any distinguishing features",
  "category": "One of: People, Electronics, Pets, Documents, Jewelry, Bags & Wallets, Keys, Clothing, Glasses & Eyewear, Watches, Headphones & Earbuds, Laptops & Tablets, Phones, Cameras, Sports Equipment, Books & Stationery, Toys, Medical Items, Umbrellas, Other",
  "tags": ["list", "of", "relevant", "searchable", "tags"],
  "color": "Primary color of the item",
  "brand": "Brand name if visible, null otherwise",
  "condition": "Item condition: new, good, fair, worn"
}

Make the tags specific and useful for searching. Include:
- Item type (wallet, phone, bag, etc.)
- Color variations
- Material if visible
- Size descriptors
- Any visible text or logos
- Distinguishing features

Return ONLY the JSON, no markdown formatting.
''';

    // Call Gemini API
    final response = await model.generateContent([
      Content.multi([TextPart(prompt), imagePart]),
    ]);

    final responseText = response.text ?? '';
    print('📝 Gemini response: $responseText');

    // Parse JSON response
    String cleanJson = responseText.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    }
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

    final jsonData = json.decode(cleanJson) as Map<String, dynamic>;
    final result = ImageAnalysisResult.fromJson(jsonData);

    print('✅ Gemini analysis complete:');
    print('   Title: ${result.title}');
    print('   Description: ${result.description}');
    print('   Category: ${result.suggestedCategory}');
    print('   Tags: ${result.tags.join(", ")}');

    return result;
  }

  /// Analyze image using Google Cloud Vision API (fallback)
  Future<ImageAnalysisResult> _analyzeWithVisionApi(File imageFile) async {
    print('🔍 Analyzing image with Cloud Vision API...');

    // Read and encode image
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // Build Vision API request
    final requestBody = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 15},
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
            {'type': 'TEXT_DETECTION', 'maxResults': 5},
            {'type': 'IMAGE_PROPERTIES', 'maxResults': 5},
          ],
        },
      ],
    };

    // Call Vision API
    final response = await http.post(
      Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Vision API error: ${response.statusCode} - ${response.body}',
      );
    }

    final responseData = json.decode(response.body);
    print('📝 Vision API response received');

    // Parse Vision API response
    final annotations = responseData['responses']?[0] ?? {};

    // Extract labels as tags
    final labelAnnotations = annotations['labelAnnotations'] as List? ?? [];
    final tags = labelAnnotations
        .map<String>((label) => (label['description'] as String).toLowerCase())
        .toList();

    // Extract objects
    final objectAnnotations =
        annotations['localizedObjectAnnotations'] as List? ?? [];
    final objects = objectAnnotations
        .map<String>((obj) => obj['name'] as String)
        .toList();

    // Extract detected text (for brand detection)
    final textAnnotations = annotations['textAnnotations'] as List? ?? [];
    String? detectedText;
    if (textAnnotations.isNotEmpty) {
      detectedText = textAnnotations[0]['description'] as String?;
    }

    // Extract dominant color
    final imageProperties = annotations['imagePropertiesAnnotation'];
    String? dominantColor;
    if (imageProperties != null) {
      final colors =
          imageProperties['dominantColors']?['colors'] as List? ?? [];
      if (colors.isNotEmpty) {
        final color = colors[0]['color'] ?? {};
        final r = (color['red'] ?? 0).toInt();
        final g = (color['green'] ?? 0).toInt();
        final b = (color['blue'] ?? 0).toInt();
        dominantColor = _rgbToColorName(r, g, b);
      }
    }

    // Build title from first object or first label
    String title = 'Unknown Item';
    if (objects.isNotEmpty) {
      title = objects.first;
    } else if (tags.isNotEmpty) {
      title = tags.first;
    }
    if (dominantColor != null) {
      title = '$dominantColor $title';
    }

    // Build description
    final descParts = <String>[];
    if (objects.isNotEmpty) {
      descParts.add('Detected: ${objects.take(3).join(", ")}.');
    }
    if (tags.isNotEmpty) {
      descParts.add('Features: ${tags.take(5).join(", ")}.');
    }
    if (detectedText != null && detectedText.length < 50) {
      descParts.add('Text visible: "$detectedText".');
    }
    final description = descParts.isNotEmpty
        ? descParts.join(' ')
        : 'Item detected via image analysis.';

    // Determine category from objects/labels
    final category = _inferCategory([...objects, ...tags]);

    // Add objects to tags
    final allTags = <String>{...tags, ...objects.map((o) => o.toLowerCase())};
    if (dominantColor != null) {
      allTags.add(dominantColor.toLowerCase());
    }

    final result = ImageAnalysisResult(
      title: _capitalizeWords(title),
      description: description,
      suggestedCategory: category,
      tags: allTags.take(10).toList(),
      color: dominantColor,
      brand: _extractBrand(detectedText),
    );

    print('✅ Vision API analysis complete:');
    print('   Title: ${result.title}');
    print('   Description: ${result.description}');
    print('   Category: ${result.suggestedCategory}');
    print('   Tags: ${result.tags.join(", ")}');

    return result;
  }

  /// Convert RGB to color name
  String _rgbToColorName(int r, int g, int b) {
    // Simple color classification
    final brightness = (r + g + b) / 3;

    if (brightness < 50) return 'Black';
    if (brightness > 220) return 'White';

    if (r > g && r > b) {
      if (r > 200 && g < 100 && b < 100) return 'Red';
      if (r > 200 && g > 100 && g < 180) return 'Orange';
      if (r > 200 && g > 180) return 'Yellow';
      return 'Red';
    }
    if (g > r && g > b) {
      return 'Green';
    }
    if (b > r && b > g) {
      if (r > 100 && g < 100) return 'Purple';
      return 'Blue';
    }
    if (r > 150 && g > 100 && b > 80 && r > g) return 'Brown';
    if (r > 180 && g > 180 && b > 180) return 'Gray';

    return 'Gray';
  }

  /// Infer category from detected labels
  String _inferCategory(List<String> labels) {
    final labelSet = labels.map((l) => l.toLowerCase()).toSet();

    // Category mapping
    final categoryKeywords = {
      'Electronics': [
        'phone',
        'laptop',
        'computer',
        'tablet',
        'electronic',
        'device',
        'charger',
        'cable',
      ],
      'Phones': [
        'phone',
        'smartphone',
        'mobile',
        'iphone',
        'android',
        'cellular',
      ],
      'Laptops & Tablets': ['laptop', 'tablet', 'notebook', 'ipad', 'macbook'],
      'Bags & Wallets': [
        'bag',
        'wallet',
        'purse',
        'backpack',
        'handbag',
        'luggage',
        'suitcase',
      ],
      'Keys': ['key', 'keychain', 'keyring'],
      'Jewelry': [
        'jewelry',
        'ring',
        'necklace',
        'bracelet',
        'earring',
        'watch',
        'gold',
        'silver',
      ],
      'Watches': ['watch', 'wristwatch', 'smartwatch'],
      'Clothing': [
        'clothing',
        'shirt',
        'pants',
        'jacket',
        'coat',
        'hat',
        'scarf',
        'gloves',
        'shoe',
      ],
      'Glasses & Eyewear': ['glasses', 'sunglasses', 'eyewear', 'spectacles'],
      'Headphones & Earbuds': ['headphones', 'earbuds', 'earphones', 'airpods'],
      'Documents': ['document', 'paper', 'card', 'id', 'passport', 'license'],
      'Cameras': ['camera', 'photography'],
      'Books & Stationery': ['book', 'notebook', 'pen', 'pencil', 'stationery'],
      'Pets': ['dog', 'cat', 'pet', 'animal', 'bird'],
      'People': ['person', 'human', 'face', 'man', 'woman', 'child'],
      'Sports Equipment': ['sports', 'ball', 'racket', 'equipment', 'fitness'],
      'Umbrellas': ['umbrella'],
      'Toys': ['toy', 'game', 'doll', 'stuffed'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (labelSet.any((label) => label.contains(keyword))) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  /// Extract brand from detected text
  String? _extractBrand(String? text) {
    if (text == null || text.isEmpty) return null;

    final knownBrands = [
      'Apple',
      'Samsung',
      'Sony',
      'Nike',
      'Adidas',
      'Gucci',
      'Louis Vuitton',
      'Dell',
      'HP',
      'Lenovo',
      'Asus',
      'Microsoft',
      'Google',
      'Bose',
      'JBL',
      'Ray-Ban',
      'Oakley',
      'Coach',
      'Michael Kors',
      'Kate Spade',
      'Fossil',
    ];

    for (final brand in knownBrands) {
      if (text.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }

    return null;
  }

  /// Capitalize each word
  String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Quick tag suggestion without full analysis
  Future<List<String>> suggestTags(String description) async {
    try {
      final prompt =
          '''
Given this item description: "$description"

Suggest 5-8 relevant search tags. Return ONLY a JSON array of strings.
Example: ["black", "leather", "wallet", "bifold", "mens"]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '[]';

      // Clean and parse
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'```\w*'), '').trim();
      }

      final tags = List<String>.from(json.decode(cleanJson));
      return tags;
    } catch (e) {
      print('⚠️ Tag suggestion error: $e');
      return [];
    }
  }
}
