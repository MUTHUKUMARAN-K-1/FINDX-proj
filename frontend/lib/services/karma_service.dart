import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/user_profile.dart';

/// Service for managing user karma points
class KarmaService {
  static final KarmaService _instance = KarmaService._internal();
  factory KarmaService() => _instance;
  KarmaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      // Create new profile if doesn't exist
      return await _createUserProfile(user);
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Create a new user profile
  Future<UserProfile> _createUserProfile(User user) async {
    final profile = UserProfile(
      id: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      karmaPoints: 0,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(profile.toFirestore());
    return profile;
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Award karma points to a user
  Future<int> awardKarma(KarmaAction action, {String? userId}) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return 0;

    try {
      final docRef = _firestore.collection('users').doc(targetUserId);

      // Use transaction for atomic update
      final newPoints = await _firestore.runTransaction<int>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          // Create profile if doesn't exist
          final user = _auth.currentUser;
          if (user != null && user.uid == targetUserId) {
            final profile = UserProfile(
              id: targetUserId,
              displayName: user.displayName,
              email: user.email,
              karmaPoints: action.points,
              createdAt: DateTime.now(),
            );
            transaction.set(docRef, profile.toFirestore());
            return action.points;
          }
          return 0;
        }

        final currentPoints = doc.data()?['karmaPoints'] ?? 0;
        final newTotal = currentPoints + action.points;

        // Update stats based on action
        final updates = <String, dynamic>{
          'karmaPoints': newTotal,
          'lastActive': Timestamp.now(),
        };

        if (action == KarmaAction.reportLostItem) {
          updates['itemsReported'] = FieldValue.increment(1);
        } else if (action == KarmaAction.reportFoundItem) {
          updates['itemsFound'] = FieldValue.increment(1);
        } else if (action == KarmaAction.helpReturnItem ||
            action == KarmaAction.verifiedReturn) {
          updates['itemsReturned'] = FieldValue.increment(1);
        }

        transaction.update(docRef, updates);
        return newTotal;
      });

      // Log karma event
      await _logKarmaEvent(targetUserId, action);

      print('✨ Awarded ${action.points} karma points. New total: $newPoints');
      return newPoints;
    } catch (e) {
      print('❌ Error awarding karma: $e');
      return 0;
    }
  }

  /// Log karma event for history
  Future<void> _logKarmaEvent(String userId, KarmaAction action) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('karma_history')
          .add({
            'action': action.name,
            'points': action.points,
            'description': action.description,
            'timestamp': Timestamp.now(),
          });
    } catch (e) {
      print('⚠️ Could not log karma event: $e');
    }
  }

  /// Get karma history for a user
  Future<List<Map<String, dynamic>>> getKarmaHistory({int limit = 20}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('karma_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting karma history: $e');
      return [];
    }
  }

  /// Get leaderboard - top users by karma
  Future<List<UserProfile>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('karmaPoints', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting leaderboard: $e');
      return [];
    }
  }

  /// Check and award daily login bonus
  Future<bool> checkDailyLoginBonus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final lastActive = (doc.data()?['lastActive'] as Timestamp?)?.toDate();
      final now = DateTime.now();

      // If last active was on a different day, award bonus
      if (lastActive == null ||
          lastActive.day != now.day ||
          lastActive.month != now.month ||
          lastActive.year != now.year) {
        await awardKarma(KarmaAction.dailyLogin);
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error checking daily bonus: $e');
      return false;
    }
  }

  /// Stream user profile for real-time updates
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }
}
