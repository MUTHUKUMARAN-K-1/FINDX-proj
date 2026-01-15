import 'package:cloud_firestore/cloud_firestore.dart';

/// Karma level badges
enum KarmaLevel {
  newcomer, // 0-49 points
  helper, // 50-199 points
  guardian, // 200-499 points
  hero, // 500-999 points
  legend, // 1000+ points
}

/// Extension for KarmaLevel
extension KarmaLevelExtension on KarmaLevel {
  String get title {
    switch (this) {
      case KarmaLevel.newcomer:
        return 'Newcomer';
      case KarmaLevel.helper:
        return 'Helper';
      case KarmaLevel.guardian:
        return 'Guardian';
      case KarmaLevel.hero:
        return 'Hero';
      case KarmaLevel.legend:
        return 'Legend';
    }
  }

  String get emoji {
    switch (this) {
      case KarmaLevel.newcomer:
        return '🌱';
      case KarmaLevel.helper:
        return '🤝';
      case KarmaLevel.guardian:
        return '🛡️';
      case KarmaLevel.hero:
        return '⭐';
      case KarmaLevel.legend:
        return '👑';
    }
  }

  int get minPoints {
    switch (this) {
      case KarmaLevel.newcomer:
        return 0;
      case KarmaLevel.helper:
        return 50;
      case KarmaLevel.guardian:
        return 200;
      case KarmaLevel.hero:
        return 500;
      case KarmaLevel.legend:
        return 1000;
    }
  }

  int get nextLevelPoints {
    switch (this) {
      case KarmaLevel.newcomer:
        return 50;
      case KarmaLevel.helper:
        return 200;
      case KarmaLevel.guardian:
        return 500;
      case KarmaLevel.hero:
        return 1000;
      case KarmaLevel.legend:
        return 9999; // Max level
    }
  }
}

/// User profile with karma points
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int karmaPoints;
  final int itemsReported;
  final int itemsReturned;
  final int itemsFound;
  final DateTime createdAt;
  final DateTime? lastActive;
  final List<String>? badges;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.karmaPoints = 0,
    this.itemsReported = 0,
    this.itemsReturned = 0,
    this.itemsFound = 0,
    required this.createdAt,
    this.lastActive,
    this.badges,
  });

  /// Get karma level based on points
  KarmaLevel get karmaLevel {
    if (karmaPoints >= 1000) return KarmaLevel.legend;
    if (karmaPoints >= 500) return KarmaLevel.hero;
    if (karmaPoints >= 200) return KarmaLevel.guardian;
    if (karmaPoints >= 50) return KarmaLevel.helper;
    return KarmaLevel.newcomer;
  }

  /// Progress to next level (0.0 - 1.0)
  double get levelProgress {
    final level = karmaLevel;
    final min = level.minPoints;
    final max = level.nextLevelPoints;
    if (max == 9999) return 1.0; // Max level
    return (karmaPoints - min) / (max - min);
  }

  /// Points needed for next level
  int get pointsToNextLevel {
    final level = karmaLevel;
    if (level == KarmaLevel.legend) return 0;
    return level.nextLevelPoints - karmaPoints;
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      karmaPoints: data['karmaPoints'] ?? 0,
      itemsReported: data['itemsReported'] ?? 0,
      itemsReturned: data['itemsReturned'] ?? 0,
      itemsFound: data['itemsFound'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      badges: data['badges'] != null ? List<String>.from(data['badges']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'karmaPoints': karmaPoints,
      'itemsReported': itemsReported,
      'itemsReturned': itemsReturned,
      'itemsFound': itemsFound,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'badges': badges,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    int? karmaPoints,
    int? itemsReported,
    int? itemsReturned,
    int? itemsFound,
    DateTime? lastActive,
    List<String>? badges,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      itemsReported: itemsReported ?? this.itemsReported,
      itemsReturned: itemsReturned ?? this.itemsReturned,
      itemsFound: itemsFound ?? this.itemsFound,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      badges: badges ?? this.badges,
    );
  }
}

/// Karma action types with point values
enum KarmaAction {
  reportLostItem, // +5 points
  reportFoundItem, // +10 points
  helpReturnItem, // +50 points
  verifiedReturn, // +100 points
  receiveThankYou, // +15 points
  dailyLogin, // +1 point
  shareItem, // +2 points
}

extension KarmaActionExtension on KarmaAction {
  int get points {
    switch (this) {
      case KarmaAction.reportLostItem:
        return 5;
      case KarmaAction.reportFoundItem:
        return 10;
      case KarmaAction.helpReturnItem:
        return 50;
      case KarmaAction.verifiedReturn:
        return 100;
      case KarmaAction.receiveThankYou:
        return 15;
      case KarmaAction.dailyLogin:
        return 1;
      case KarmaAction.shareItem:
        return 2;
    }
  }

  String get description {
    switch (this) {
      case KarmaAction.reportLostItem:
        return 'Reported a lost item';
      case KarmaAction.reportFoundItem:
        return 'Reported a found item';
      case KarmaAction.helpReturnItem:
        return 'Helped return an item';
      case KarmaAction.verifiedReturn:
        return 'Verified item return';
      case KarmaAction.receiveThankYou:
        return 'Received a thank you';
      case KarmaAction.dailyLogin:
        return 'Daily login bonus';
      case KarmaAction.shareItem:
        return 'Shared an item';
    }
  }
}
