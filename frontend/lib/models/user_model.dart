import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user in the application
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? fcmToken;
  final String? phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isAnonymous;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
    this.isAnonymous = false,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      phoneNumber: map['phoneNumber'],
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'phoneNumber': phoneNumber,
      'isAnonymous': isAnonymous,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'phoneNumber': phoneNumber,
      'isAnonymous': isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? fcmToken,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAnonymous,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  /// Get initials for avatar
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = displayName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
