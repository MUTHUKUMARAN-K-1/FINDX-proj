import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for Firebase Cloud Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image to Firebase Storage
  /// Returns the download URL on success, null on failure
  Future<String?> uploadImage(File image) async {
    try {
      print('📤 Starting image upload...');
      print('📁 File path: ${image.path}');
      print('📏 File exists: ${await image.exists()}');

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final Reference ref = _storage.ref().child('images/$fileName');

      print('🎯 Uploading to: images/$fileName');

      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        image,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      print('✅ Upload complete! State: ${snapshot.state}');

      // Get and return download URL
      final url = await snapshot.ref.getDownloadURL();
      print('🔗 Download URL: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload an image with progress tracking
  /// Returns a stream of upload progress (0.0 to 1.0)
  Stream<double> uploadImageWithProgress(File image) async* {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final Reference ref = _storage.ref().child('images/$fileName');

      final UploadTask uploadTask = ref.putFile(image);

      await for (final snapshot in uploadTask.snapshotEvents) {
        if (snapshot.totalBytes > 0) {
          yield snapshot.bytesTransferred / snapshot.totalBytes;
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      yield -1; // Indicate error
    }
  }

  /// Get upload result after uploadImageWithProgress completes
  Future<String?> getDownloadUrlAfterUpload(File image) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
    final Reference ref = _storage.ref().child('images/$fileName');

    try {
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Delete an image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Get reference from URL
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> images) async {
    final List<String> urls = [];

    for (final image in images) {
      final url = await uploadImage(image);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Get file metadata
  Future<FullMetadata?> getFileMetadata(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Error getting file metadata: $e');
      return null;
    }
  }
}
