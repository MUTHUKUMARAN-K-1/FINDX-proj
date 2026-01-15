import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service to find and alert users who were near a lost item location
class NearbyUsersService {
  static final NearbyUsersService _instance = NearbyUsersService._internal();
  factory NearbyUsersService() => _instance;
  NearbyUsersService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find users within a given radius of a location at a specific time
  /// [latitude] and [longitude] - the location of the lost item
  /// [incidentTime] - when the item was lost
  /// [radiusKm] - search radius in kilometers (default 1km)
  /// [timeWindowMinutes] - time window before/after incident (default 30 min)
  Future<List<String>> findNearbyUsers({
    required double latitude,
    required double longitude,
    required DateTime incidentTime,
    double radiusKm = 1.0,
    int timeWindowMinutes = 30,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // Calculate time window
      final startTime = incidentTime.subtract(
        Duration(minutes: timeWindowMinutes),
      );
      final endTime = incidentTime.add(Duration(minutes: timeWindowMinutes));

      // Calculate geohash for the target location
      final targetGeohash = _calculateGeohash(
        latitude,
        longitude,
        precision: 5,
      );

      // Get neighboring geohashes for broader coverage
      final geohashPrefixes = _getGeohashNeighbors(targetGeohash);

      // Query for users in the area during the time window
      final Set<String> nearbyUserIds = {};

      for (final prefix in geohashPrefixes) {
        final querySnapshot = await _firestore
            .collection('user_locations')
            .where('geohash', isGreaterThanOrEqualTo: prefix)
            .where('geohash', isLessThan: '${prefix}z')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: startTime.toIso8601String(),
            )
            .where('createdAt', isLessThanOrEqualTo: endTime.toIso8601String())
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;

          if (userId != null && lat != null && lng != null) {
            // Exclude the user who reported the item
            if (userId == currentUserId) continue;

            // Calculate actual distance for accuracy
            final distance = _calculateDistance(latitude, longitude, lat, lng);
            if (distance <= radiusKm) {
              nearbyUserIds.add(userId);
            }
          }
        }
      }

      print(
        '🔍 Found ${nearbyUserIds.length} nearby users within ${radiusKm}km',
      );
      return nearbyUserIds.toList();
    } catch (e) {
      print('Error finding nearby users: $e');
      return [];
    }
  }

  /// Alert nearby users about a lost item
  /// Falls back to alerting all active users if no nearby users found
  Future<int> alertNearbyUsers({
    required double latitude,
    required double longitude,
    required DateTime incidentTime,
    required String itemDescription,
    required String itemId,
    String? imageUrl,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // First try to find nearby users with wider parameters
      List<String> nearbyUserIds = await findNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        incidentTime: incidentTime,
        radiusKm: 5.0, // Increased radius to 5km
        timeWindowMinutes: 120, // Increased to 2 hours
      );

      // If no nearby users found, get all users with FCM tokens (for testing/demo)
      if (nearbyUserIds.isEmpty) {
        print('📢 No nearby users found, falling back to all active users');
        nearbyUserIds = await _getAllActiveUserIds(
          excludeUserId: currentUserId,
        );
      }

      if (nearbyUserIds.isEmpty) {
        print('📢 No users to alert');
        return 0;
      }

      print('📢 Alerting ${nearbyUserIds.length} users...');

      // Get FCM tokens and send notifications
      int alertsSent = 0;
      for (final userId in nearbyUserIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final fcmToken = userDoc.data()?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendAlertNotification(
            fcmToken: fcmToken,
            userId: userId,
            itemDescription: itemDescription,
            itemId: itemId,
            latitude: latitude,
            longitude: longitude,
          );
          alertsSent++;
        } else {
          print('⚠️ No FCM token for user: $userId');
        }
      }

      print('📢 Sent $alertsSent alerts');
      return alertsSent;
    } catch (e) {
      print('Error alerting users: $e');
      return 0;
    }
  }

  /// Get all active users with FCM tokens (fallback for when no nearby users found)
  Future<List<String>> _getAllActiveUserIds({String? excludeUserId}) async {
    try {
      // Get all users and filter in memory for those with FCM tokens
      // Firestore doesn't support isNull: false properly
      final querySnapshot = await _firestore
          .collection('users')
          .limit(50) // Get more users to filter from
          .get();

      final userIds = <String>[];
      for (final doc in querySnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null &&
            fcmToken.isNotEmpty &&
            doc.id != excludeUserId) {
          userIds.add(doc.id);
          if (userIds.length >= 20) break; // Limit to 20 users
        }
      }

      print('🔍 Found ${userIds.length} users with FCM tokens');
      return userIds;
    } catch (e) {
      print('Error getting active users: $e');
      return [];
    }
  }

  /// Send a push notification to a nearby user via FCM HTTP API
  Future<void> _sendAlertNotification({
    required String fcmToken,
    required String userId,
    required String itemDescription,
    required String itemId,
    required double latitude,
    required double longitude,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      // Calculate distance if user location is known
      String distanceText = '';
      if (userLatitude != null && userLongitude != null) {
        final distanceKm = _calculateDistance(
          latitude,
          longitude,
          userLatitude,
          userLongitude,
        );
        if (distanceKm < 1) {
          distanceText = '${(distanceKm * 1000).toInt()}m away';
        } else {
          distanceText = '${distanceKm.toStringAsFixed(1)}km away';
        }
      }

      final title = distanceText.isNotEmpty
          ? '🚨 Lost item $distanceText!'
          : '🚨 Someone lost an item near you!';

      final body = itemDescription.length > 50
          ? '${itemDescription.substring(0, 50)}...'
          : itemDescription;

      // Store notification in Firestore for in-app display
      try {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'nearby_alert',
          'title': title,
          'body': body,
          'itemId': itemId,
          'latitude': latitude,
          'longitude': longitude,
          'distance': distanceText,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Notification saved to Firestore for user: $userId');
      } catch (firestoreError) {
        print(
          '⚠️ Could not save to Firestore (will still send push): $firestoreError',
        );
      }

      // Send actual FCM push notification via HTTP API
      print('📤 Sending FCM to token: ${fcmToken.substring(0, 20)}...');
      await _sendFcmNotification(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: {
          'type': 'nearby_alert',
          'itemId': itemId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'distance': distanceText,
        },
      );

      print('📱 Push notification sent to user: $userId');
    } catch (e, stackTrace) {
      print('Error sending alert notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Send FCM notification via backend server (FCM V1 API)
  /// The backend handles secure authentication with Firebase Admin SDK
  Future<void> _sendFcmNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Backend URL - update this to your server address
      // For local development: http://10.0.2.2:8000 (Android emulator)
      // For physical device: use your computer's IP address
      const backendUrl = 'http://192.168.29.15:8000'; // Your network IP

      final response = await http.post(
        Uri.parse('$backendUrl/send-notification/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fcmToken': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM notification sent via backend');
      } else {
        print('❌ Backend FCM error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
      // Fallback: notification is already stored in Firestore
      // User will see it in-app even if push fails
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// Calculate geohash for a given latitude and longitude
  String _calculateGeohash(double lat, double lng, {int precision = 5}) {
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

  /// Get neighboring geohashes for broader area coverage
  List<String> _getGeohashNeighbors(String geohash) {
    // For simplicity, we'll just use the geohash prefix
    // In production, you'd calculate actual neighbors
    if (geohash.length <= 1) return [geohash];

    final prefix = geohash.substring(0, geohash.length - 1);
    return [prefix];
  }
}
