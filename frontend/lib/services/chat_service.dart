import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a chat message
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }
}

/// Model for a chat conversation
class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final String? itemId; // Optional: linked item
  final String? itemTitle;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.itemId,
    this.itemTitle,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(
        data['participantNames'] ?? {},
      ),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      itemId: data['itemId'],
      itemTitle: data['itemTitle'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'itemId': itemId,
      'itemTitle': itemTitle,
    };
  }

  /// Get unread count for a specific user
  int getUnreadCountFor(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Get the other participant's name (for 1:1 chats)
  String getOtherParticipantName(String currentUserId) {
    final otherId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherId] ?? 'Unknown';
  }
}

/// Service for Firebase Chat functionality
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');

  /// Get all conversations for a user
  Stream<List<ChatConversation>> getConversations(String userId) {
    // Note: Removed orderBy to avoid composite index requirement
    // Sorting is done client-side instead
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map((doc) => ChatConversation.fromFirestore(doc))
              .toList();
          // Sort client-side by lastMessageTime
          conversations.sort((a, b) {
            final aTime = a.lastMessageTime ?? DateTime(1970);
            final bTime = b.lastMessageTime ?? DateTime(1970);
            return bTime.compareTo(aTime); // Descending
          });
          return conversations;
        });
  }

  /// Get messages for a specific chat
  Stream<List<ChatMessage>> getMessages(String chatId) {
    // Note: Removed orderBy to avoid composite index requirement
    // Sorting is done client-side instead
    return _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          // Sort client-side by timestamp
          messages.sort(
            (a, b) => a.timestamp.compareTo(b.timestamp),
          ); // Ascending
          return messages;
        });
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
    String? imageUrl,
  }) async {
    // Add the message
    await _messagesCollection.add(
      ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      ).toFirestore(),
    );

    // Update the chat's last message
    await _chatsCollection.doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });

    // Increment unread count for other participants
    final chatDoc = await _chatsCollection.doc(chatId).get();
    final chat = ChatConversation.fromFirestore(chatDoc);

    final updates = <String, dynamic>{};
    for (final participantId in chat.participants) {
      if (participantId != senderId) {
        updates['unreadCount.$participantId'] = FieldValue.increment(1);
      }
    }

    if (updates.isNotEmpty) {
      await _chatsCollection.doc(chatId).update(updates);
    }
  }

  /// Create or get existing chat between two users
  Future<String> getOrCreateChat({
    required String userId1,
    required String userName1,
    required String userId2,
    required String userName2,
    String? itemId,
    String? itemTitle,
  }) async {
    // Check if a chat already exists between these users
    final existingChats = await _chatsCollection
        .where('participants', arrayContains: userId1)
        .get();

    for (final doc in existingChats.docs) {
      final chat = ChatConversation.fromFirestore(doc);
      if (chat.participants.contains(userId2)) {
        // If itemId is provided, check if it matches
        if (itemId == null || chat.itemId == itemId) {
          return doc.id;
        }
      }
    }

    // Create new chat
    final chatDoc = await _chatsCollection.add({
      'participants': [userId1, userId2],
      'participantNames': {userId1: userName1, userId2: userName2},
      'lastMessage': null,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': null,
      'unreadCount': {userId1: 0, userId2: 0},
      'itemId': itemId,
      'itemTitle': itemTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatDoc.id;
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    // Reset unread count for user
    await _chatsCollection.doc(chatId).update({'unreadCount.$userId': 0});

    // Mark all unread messages as read
    final unreadMessages = await _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      final message = ChatMessage.fromFirestore(doc);
      if (message.senderId != userId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  /// Get total unread count for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final chat = ChatConversation.fromFirestore(doc);
            total += chat.getUnreadCountFor(userId);
          }
          return total;
        });
  }

  /// Delete a chat (and all its messages)
  Future<void> deleteChat(String chatId) async {
    // Delete all messages
    final messages = await _messagesCollection
        .where('chatId', isEqualTo: chatId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat
    batch.delete(_chatsCollection.doc(chatId));

    await batch.commit();
  }
}
