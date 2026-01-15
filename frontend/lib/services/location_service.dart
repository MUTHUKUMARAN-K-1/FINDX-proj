import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _placeName;
  String? _fullAddress;
  Timer? _locationUpdateTimer;
  bool _isInitialized = false;

  Position? get currentPosition => _currentPosition;
  String? get placeName => _placeName;
  String? get fullAddress => _fullAddress;
  bool get isInitialized => _isInitialized;

  /// Initialize and start periodic location updates (every 1 minute)
  Future<bool> initializeAndSaveLocation() async {
    try {
      print('Starting location service initialization...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('Location services are disabled');
        // On Windows, open location settings
        await Geolocator.openLocationSettings();
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('Location permission denied by user');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        await Geolocator.openAppSettings();
        return false;
      }

      _isInitialized = true;
      print('Location service initialized successfully!');

      // Get location immediately on first run
      await _fetchAndSaveLocation();

      // Start periodic updates every 1 minute (60 seconds)
      _startPeriodicLocationUpdates();

      return true;
    } catch (e) {
      print('Error initializing location: $e');
      return false;
    }
  }

  /// Show location permission dialog (call from UI context)
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Location Access'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FindX needs access to your location to:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Find lost items near you')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Report items with accurate location')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Connect you with nearby finders')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Your location is sent to the server every minute to keep your location up-to-date.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow Location'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Start periodic location updates every 2 minutes
  void _startPeriodicLocationUpdates() {
    // Cancel any existing timer
    _locationUpdateTimer?.cancel();

    // Update every 2 minutes (120 seconds)
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 2), (
      timer,
    ) async {
      print('Periodic location update triggered (every 2 minutes)');
      await _fetchAndSaveLocation();
    });

    print('Started periodic location updates (every 2 minutes)');
  }

  /// Fetch current location and save to the backend
  Future<void> _fetchAndSaveLocation() async {
    try {
      if (!_isInitialized) {
        print('Location service not initialized');
        return;
      }

      print('Fetching current location...');

      // Get current position with high accuracy
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      if (_currentPosition != null) {
        print(
          'Got location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        );

        // Send location to the backend
        await _sendLocationToBackend(_currentPosition!);

        print('Location updated at ${DateTime.now()}');
      } else {
        print('Position is null');
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  /// Send location data to Firebase for nearby user tracking
  Future<void> _sendLocationToBackend(Position position) async {
    try {
      // Get place name for better context
      await _getPlaceName(position.latitude, position.longitude);

      // Save to Firebase for real-time location tracking
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Calculate geohash for efficient geo-queries (precision 6 = ~1km)
        final geohash = _calculateGeohash(
          position.latitude,
          position.longitude,
          precision: 6,
        );

        // Store in user_locations collection
        await FirebaseFirestore.instance.collection('user_locations').add({
          'userId': userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'geohash': geohash,
          'placeName': _placeName,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': DateTime.now().toIso8601String(),
        });

        print(
          '📍 Location saved to Firebase: ${_placeName ?? "Unknown"} (geohash: $geohash)',
        );
      } else {
        print('📍 Location cached locally (user not logged in)');
      }
    } catch (e) {
      print('Error processing location: $e');
    }
  }

  /// Calculate geohash for a given latitude and longitude
  /// Precision 6 = ~1.2km, 7 = ~153m, 8 = ~19m
  String _calculateGeohash(double lat, double lng, {int precision = 6}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var minLat = -90.0, maxLat = 90.0;
    var minLng = -180.0, maxLng = 180.0;
    var hash = '';
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (lng > mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        hash += base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return hash;
  }

  /// Get real place name from coordinates using reverse geocoding
  Future<void> _getPlaceName(double latitude, double longitude) async {
    try {
      print('Getting place name for: $latitude, $longitude');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Build a more detailed location name
        List<String> locationParts = [];

        // Add street name if available
        if (place.street != null &&
            place.street!.isNotEmpty &&
            !place.street!.contains('+')) {
          locationParts.add(place.street!);
        }

        // Add sub-locality (neighborhood like "Anna Nagar")
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationParts.add(place.subLocality!);
        }

        // Add locality (city like "Chennai")
        if (place.locality != null && place.locality!.isNotEmpty) {
          // Only add if different from sub-locality
          if (place.subLocality == null ||
              place.locality != place.subLocality) {
            locationParts.add(place.locality!);
          }
        }

        // Set the detailed place name
        if (locationParts.isNotEmpty) {
          _placeName = locationParts.join(', ');
        } else {
          _placeName =
              place.administrativeArea ??
              place.subAdministrativeArea ??
              'Unknown';
        }

        // Build full address dynamically from available data
        List<String> addressParts = [];

        // Add street number/name
        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.street) {
          addressParts.add(place.name!);
        }

        // Add street
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }

        // Add sub-locality (neighborhood)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        // Add locality (city/town like Tambaram)
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        // Add sub-administrative area (district)
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            place.subAdministrativeArea != place.locality) {
          addressParts.add(place.subAdministrativeArea!);
        }

        // Add administrative area (state)
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        // Add postal code
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        // Add country
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        _fullAddress = addressParts.join(', ');

        print('Real Place Name: $_placeName');
        print('Full Address: $_fullAddress');
      }
    } catch (e) {
      print('Error getting place name: $e');
      _placeName = 'Unknown';
      _fullAddress = 'Unable to get address';
    }
  }

  /// Stop periodic location updates
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    print('Stopped periodic location updates');
  }

  /// Manually trigger a location update
  Future<void> forceLocationUpdate() async {
    await _fetchAndSaveLocation();
  }

  /// Dispose the service
  void dispose() {
    stopLocationUpdates();
  }
}
