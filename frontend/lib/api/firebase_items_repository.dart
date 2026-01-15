import 'dart:io';
import 'package:frontend/models/item.dart';
import 'package:frontend/services/firestore_service.dart';
import 'package:frontend/services/storage_service.dart';

/// Repository for managing items using Firebase (Firestore + Storage)
class FirebaseItemsRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  /// Add a new item with optional image upload
  Future<String> addItem(Item item, {File? image}) async {
    String? imageUrl;

    // Upload image if provided
    if (image != null) {
      imageUrl = await _storageService.uploadImage(image);
    }

    // Create item with image URL
    final itemWithImage = item.copyWith(imageUrl: imageUrl ?? item.imageUrl);

    // Add to Firestore
    return await _firestoreService.addItem(itemWithImage);
  }

  /// Get items as a stream (real-time updates)
  Stream<List<Item>> getItems({required bool isLost}) {
    return _firestoreService.getItems(isLost: isLost);
  }

  /// Get all items as a stream (both lost and found)
  Stream<List<Item>> getAllItems() {
    return _firestoreService.getItems();
  }

  /// Get items once (not real-time)
  Future<List<Item>> getItemsOnce({required bool isLost}) {
    return _firestoreService.getItemsOnce(isLost: isLost);
  }

  /// Get a single item by ID
  Future<Item?> getItemById(String id) {
    return _firestoreService.getItemById(id);
  }

  /// Update an existing item
  Future<void> updateItem(String id, Item item, {File? newImage}) async {
    String? imageUrl = item.imageUrl;

    // Upload new image if provided
    if (newImage != null) {
      imageUrl = await _storageService.uploadImage(newImage);
    }

    await _firestoreService.updateItem(id, {
      ...item.toFirestore(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
  }

  /// Update item status
  Future<void> updateItemStatus(String id, String status) async {
    await _firestoreService.updateItem(id, {'status': status});
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    // Get item to delete associated image
    final item = await _firestoreService.getItemById(itemId);
    if (item?.imageUrl != null) {
      await _storageService.deleteImage(item!.imageUrl!);
    }

    await _firestoreService.deleteItem(itemId);
  }

  /// Search items by description
  Future<List<Item>> searchItems(String query) {
    return _firestoreService.searchItems(query);
  }

  /// Get nearby items
  Future<List<Item>> getNearbyItems({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) {
    return _firestoreService.getNearbyItems(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Get items by user ID
  Stream<List<Item>> getUserItems(String userId) {
    return _firestoreService.getUserItems(userId);
  }
}
