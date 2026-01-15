import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/item.dart';

/// Service for Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('items');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ============ ITEMS CRUD ============

  /// Add a new item to Firestore
  Future<String> addItem(Item item) async {
    try {
      final docRef = await _itemsCollection.add({
        'description': item.description,
        'imageUrl': item.imageUrl,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'timestamp': Timestamp.fromDate(item.timestamp),
        'isLost': item.isLost,
        'userId': item.userId,
        'category': item.category,
        'status': item.status,
        'contactInfo': item.contactInfo,
        'placeName': item.placeName,
        'tags': item.tags,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Item saved with tags: ${item.tags}');
      return docRef.id;
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  /// Get all items as a stream (real-time updates)
  Stream<List<Item>> getItems({bool? isLost}) {
    Query<Map<String, dynamic>> query = _itemsCollection.orderBy(
      'createdAt',
      descending: true,
    );

    if (isLost != null) {
      query = query.where('isLost', isEqualTo: isLost);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
    });
  }

  /// Get items once (not real-time)
  Future<List<Item>> getItemsOnce({bool? isLost}) async {
    Query<Map<String, dynamic>> query = _itemsCollection.orderBy(
      'createdAt',
      descending: true,
    );

    if (isLost != null) {
      query = query.where('isLost', isEqualTo: isLost);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  /// Get a single item by ID
  Future<Item?> getItemById(String id) async {
    try {
      final doc = await _itemsCollection.doc(id).get();
      if (doc.exists) {
        return Item.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  /// Update an existing item
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _itemsCollection.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  /// Delete an item
  Future<void> deleteItem(String id) async {
    try {
      await _itemsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  /// Search items by description
  Future<List<Item>> searchItems(String query) async {
    // Firestore doesn't support full-text search natively
    // This is a simple prefix search - for production, consider Algolia
    final snapshot = await _itemsCollection
        .orderBy('description')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  /// Get items near a location
  Future<List<Item>> getNearbyItems({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    // Simple bounding box query
    // For production, consider using GeoFlutterFire for proper geoqueries
    final latDelta = radiusKm / 111; // ~111km per degree
    final lonDelta = radiusKm / (111 * (1 / (latitude.abs() + 0.0001)));

    final snapshot = await _itemsCollection
        .where('latitude', isGreaterThan: latitude - latDelta)
        .where('latitude', isLessThan: latitude + latDelta)
        .get();

    // Filter by longitude in memory (Firestore limitation)
    return snapshot.docs
        .map((doc) => Item.fromFirestore(doc))
        .where(
          (item) =>
              item.longitude >= longitude - lonDelta &&
              item.longitude <= longitude + lonDelta,
        )
        .toList();
  }

  /// Get items by user ID
  Stream<List<Item>> getUserItems(String userId) {
    return _itemsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
        });
  }

  // ============ USER OPERATIONS ============

  /// Create or update user profile
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? fcmToken,
  }) async {
    await _usersCollection.doc(uid).set({
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.data();
  }

  /// Update FCM token for a user
  Future<void> updateFcmToken(String uid, String token) async {
    await _usersCollection.doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update user profile with arbitrary data
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _usersCollection.doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
