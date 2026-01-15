import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/firestore_service.dart';
import 'dart:io' show Platform;

/// Service for Firebase Cloud Messaging (Push Notifications)
/// Note: FCM is only supported on Android, iOS, and Web.
/// Windows and Linux desktop are not supported.
class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if FCM is supported on current platform
  bool get isSupported {
    if (kIsWeb) return true;
    try {
      if (Platform.isWindows || Platform.isLinux) return false;
    } catch (_) {}
    return true;
  }

  /// Initialize FCM and request permissions
  Future<void> init({String? userId}) async {
    // Skip FCM on unsupported platforms (Windows/Linux)
    if (!isSupported) {
      print('ℹ️ FCM: Skipping - not supported on Windows/Linux desktop');
      return;
    }

    try {
      // Request permission (iOS and Web)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM: User granted permission');
        await _setupToken(userId);
        _setupMessageHandlers();
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('📱 FCM: User granted provisional permission');
        await _setupToken(userId);
        _setupMessageHandlers();
      } else {
        print('❌ FCM: User denied permission');
      }
    } catch (e) {
      print('⚠️ FCM init error: $e');
    }
  }

  /// Setup FCM token and save to Firestore
  Future<void> _setupToken(String? userId) async {
    try {
      // Get the token
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Auto-detect current user if not passed
      final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

      // Save token to Firestore if user is logged in
      if (currentUserId != null && _fcmToken != null) {
        await _firestoreService.updateFcmToken(currentUserId, _fcmToken!);
        print('✅ FCM Token saved to Firestore for user: $currentUserId');
      } else {
        print('⚠️ FCM Token not saved: user not logged in');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');

        // Auto-detect current user on refresh too
        final userForRefresh = FirebaseAuth.instance.currentUser?.uid;
        if (userForRefresh != null) {
          await _firestoreService.updateFcmToken(userForRefresh, newToken);
          print('✅ Refreshed FCM Token saved to Firestore');
        }
      });
    } catch (e) {
      print('⚠️ FCM token setup error: $e');
    }
  }

  /// Force save the current FCM token to Firestore for the current user
  /// Call this after user logs in or on app restart
  Future<void> forceSaveToken() async {
    if (!isSupported) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('⚠️ Cannot save FCM token: No user logged in');
        return;
      }

      // Get token if we don't have it
      _fcmToken ??= await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        await _firestoreService.updateFcmToken(userId, _fcmToken!);
        print('✅ FCM Token force-saved for user: $userId');
      }
    } catch (e) {
      print('⚠️ Error force-saving FCM token: $e');
    }
  }

  /// Setup message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Got a message whilst in the foreground!');
      print('   Message data: ${message.data}');

      if (message.notification != null) {
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');

        // You can show a local notification here using flutter_local_notifications
        _showLocalNotification(message);
      }
    });

    // Handle background messages (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Message opened from background!');
      print('   Message data: ${message.data}');

      // Handle navigation based on message data
      _handleMessageNavigation(message);
    });

    // Check if app was opened from a terminated state
    _checkInitialMessage();
  }

  /// Check if app was launched from a notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      print('📬 App opened from terminated state via notification!');
      _handleMessageNavigation(initialMessage);
    }
  }

  /// Handle navigation based on notification data
  void _handleMessageNavigation(RemoteMessage message) {
    // Extract navigation data
    final data = message.data;

    if (data.containsKey('itemId')) {
      // Navigate to item details
      final itemId = data['itemId'];
      print('Navigate to item: $itemId');
      // You can use a global navigator key or stream to trigger navigation
    } else if (data.containsKey('chatId')) {
      // Navigate to chat
      final chatId = data['chatId'];
      print('Navigate to chat: $chatId');
    }
  }

  /// Show a local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    // This is a placeholder - integrate with flutter_local_notifications
    // for proper local notification display
    if (kDebugMode) {
      print('🔔 Notification: ${message.notification?.title}');
      print('   ${message.notification?.body}');
    }
  }

  /// Subscribe to a topic (e.g., for category-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('⚠️ Subscribe error: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('⚠️ Unsubscribe error: $e');
    }
  }

  /// Get APNS token (iOS only)
  Future<String?> getApnsToken() async {
    return await _firebaseMessaging.getAPNSToken();
  }

  /// Delete the FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');
    } catch (e) {
      print('⚠️ Delete token error: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 Handling a background message: ${message.messageId}');
  print('   Data: ${message.data}');
}
