import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:frontend/utils/env_config.dart';

/// Service for Google Places autocomplete and geocoding
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  // Use API key from environment config
  static String get _apiKey => EnvConfig.googleMapsApiKey;

  // Store user's current location for distance calculations
  double? _userLat;
  double? _userLng;

  /// Set user's current location for distance calculations
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
  }

  /// Get place predictions (autocomplete) for a search query with distance
  Future<List<PlacePrediction>> getPlacePredictions(
    String query, {
    double? userLat,
    double? userLng,
  }) async {
    if (query.isEmpty || query.length < 2) return [];

    // Use provided location or stored location
    final lat = userLat ?? _userLat;
    final lng = userLng ?? _userLng;

    print('📍 PlacesService: query="$query", userLat=$lat, userLng=$lng');

    try {
      // Use NEW Places API (New) format
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete',
      );

      // Build request body
      final Map<String, dynamic> body = {
        'input': query,
        'includedRegionCodes': ['in'],
      };

      // Add location bias if available
      if (lat != null && lng != null) {
        body['locationBias'] = {
          'circle': {
            'center': {'latitude': lat, 'longitude': lng},
            'radius': 50000.0,
          },
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: json.encode(body),
      );

      print('📍 Places API status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List? ?? [];

        print('📍 Got ${suggestions.length} suggestions');

        // Parse predictions
        List<PlacePrediction> parsedPredictions = suggestions
            .where((s) => s['placePrediction'] != null)
            .map((s) => PlacePrediction.fromNewApi(s['placePrediction']))
            .toList();

        // If we have user location, fetch distances in PARALLEL
        if (lat != null && lng != null && parsedPredictions.isNotEmpty) {
          final toFetch = parsedPredictions.take(5).toList();
          final detailsFutures = toFetch.map(
            (p) => getPlaceDetailsNew(p.placeId),
          );
          final allDetails = await Future.wait(detailsFutures);

          List<PlacePrediction> results = [];
          for (int i = 0; i < toFetch.length; i++) {
            final details = allDetails[i];
            if (details != null) {
              final distance = _calculateDistance(
                lat,
                lng,
                details.latitude,
                details.longitude,
              );
              results.add(toFetch[i].copyWithDistance(distance));
            } else {
              results.add(toFetch[i]);
            }
          }
          return results;
        }

        return parsedPredictions;
      } else {
        final errorBody = json.decode(response.body);
        print(
          '📍 Places API error: ${errorBody['error']?['message'] ?? response.body}',
        );
      }
      return [];
    } catch (e) {
      print('🗺️ Places autocomplete error: $e');
      return [];
    }
  }

  /// Get place details using new API
  Future<PlaceDetails?> getPlaceDetailsNew(String placeId) async {
    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');

      final response = await http.get(
        url,
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'location,formattedAddress,displayName',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['location'];
        if (location != null) {
          return PlaceDetails(
            latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
            formattedAddress: data['formattedAddress'] ?? '',
            name: data['displayName']?['text'] ?? '',
          );
        }
      }
      return null;
    } catch (e) {
      print('🗺️ Place details (new) error: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Get place details (legacy API - for backward compatibility)
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    // Use new API internally
    return getPlaceDetailsNew(placeId);
  }

  /// Reverse geocode: Get address from latitude/longitude
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Use new Geocoding API
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('🗺️ Reverse geocode error: $e');
      return null;
    }
  }

  /// Get a shorter, more readable address from coordinates
  Future<String?> getShortAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&result_type=sublocality|locality|administrative_area_level_2'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] as String?;
        }
      }
      // Fallback to full address
      return await getAddressFromCoordinates(lat, lng);
    } catch (e) {
      print('🗺️ Short address error: $e');
      return null;
    }
  }
}

/// Place prediction from autocomplete
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? distanceKm;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.distanceKm,
  });

  /// Get formatted distance text (e.g., "4.2 km")
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Factory for legacy API response
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'] ?? '',
    );
  }

  /// Factory for NEW Places API response
  factory PlacePrediction.fromNewApi(Map<String, dynamic> json) {
    final text = json['text'] ?? {};
    final structuredFormat = json['structuredFormat'] ?? {};
    final mainTextObj = structuredFormat['mainText'] ?? {};
    final secondaryTextObj = structuredFormat['secondaryText'] ?? {};

    return PlacePrediction(
      placeId: json['placeId'] ?? json['place_id'] ?? '',
      description: text['text'] ?? '',
      mainText: mainTextObj['text'] ?? text['text'] ?? '',
      secondaryText: secondaryTextObj['text'] ?? '',
    );
  }

  /// Create a copy with distance
  PlacePrediction copyWithDistance(double distance) {
    return PlacePrediction(
      placeId: placeId,
      description: description,
      mainText: mainText,
      secondaryText: secondaryText,
      distanceKm: distance,
    );
  }
}

/// Place details with coordinates
class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;

  PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    return PlaceDetails(
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
