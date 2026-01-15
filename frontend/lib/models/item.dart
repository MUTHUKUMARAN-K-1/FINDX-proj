import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a lost/found item
enum ItemStatus {
  active, // Item is still lost/available
  claimed, // Someone has claimed the item
  returned, // Item has been returned to owner
  expired, // Listing has expired
}

/// Model representing a lost or found item
class Item {
  final String id;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isLost;
  final String? userId;
  final String? category;
  final String? status;
  final String? contactInfo;
  final String? placeName;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Item({
    required this.id,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.isLost,
    this.userId,
    this.category,
    this.status,
    this.contactInfo,
    this.placeName,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Item from Firestore document
  factory Item.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Item(
      id: doc.id,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(
              data['timestamp'] ?? DateTime.now().toIso8601String(),
            ),
      isLost: data['isLost'] ?? true,
      userId: data['userId'],
      category: data['category'],
      status: data['status'] ?? 'active',
      contactInfo: data['contactInfo'],
      placeName: data['placeName'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create Item from Map (for REST API compatibility)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: map['timestamp'] is String
          ? DateTime.parse(map['timestamp'])
          : (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLost: map['isLost'] ?? true,
      userId: map['userId'],
      category: map['category'],
      status: map['status'],
      contactInfo: map['contactInfo'],
      placeName: map['placeName'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  /// Convert to Map for REST API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isLost': isLost,
      'userId': userId,
      'category': category,
      'status': status,
      'contactInfo': contactInfo,
      'placeName': placeName,
      'tags': tags,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'isLost': isLost,
      'userId': userId,
      'category': category,
      'status': status ?? 'active',
      'contactInfo': contactInfo,
      'placeName': placeName,
      'tags': tags,
    };
  }

  /// Create a copy with modified fields
  Item copyWith({
    String? id,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    bool? isLost,
    String? userId,
    String? category,
    String? status,
    String? contactInfo,
    String? placeName,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      isLost: isLost ?? this.isLost,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      status: status ?? this.status,
      contactInfo: contactInfo ?? this.contactInfo,
      placeName: placeName ?? this.placeName,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, description: $description, isLost: $isLost, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
