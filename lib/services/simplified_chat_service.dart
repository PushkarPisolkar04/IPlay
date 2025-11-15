import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/notification_service.dart';

/// SimplifiedChatService - Education-focused chat system
/// Only allows teacher-to-student one-on-one messaging
/// No student-to-student messaging, no group chats
class SimplifiedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create a teacher-to-student chat
  /// Both teachers and students can initiate conversations
  Future<String> createTeacherStudentChat({
    required String teacherId,
    required String studentId,
  }) async {
    // Verify both users exist
    final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
    final studentDoc = await _firestore.collection('users').doc(studentId).get();
    
    if (!teacherDoc.exists) {
      throw Exception('Teacher not found');
    }
    
    if (!studentDoc.exists) {
      throw Exception('Student not found');
    }
    
    final teacherData = teacherDoc.data()!;
    final studentData = studentDoc.data()!;
    
    // Verify roles
    if (teacherData['role'] != 'teacher' && teacherData['isPrincipal'] != true) {
      throw Exception('Invalid teacher');
    }
    
    if (studentData['role'] != 'student') {
      throw Exception('Invalid student');
    }

    // Verify student is in teacher's classroom
    final classrooms = await _firestore
        .collection('classrooms')
        .where('teacherId', isEqualTo: teacherId)
        .where('studentIds', arrayContains: studentId)
        .get();

    if (classrooms.docs.isEmpty) {
      throw Exception('Student must be in teacher\'s classroom');
    }

    // Check if chat already exists
    final chatId = _generateChatId(teacherId, studentId);
    final existingChat = await _firestore.collection('chats').doc(chatId).get();
    
    if (existingChat.exists) {
      return chatId;
    }

    // Create chat
    await _firestore.collection('chats').doc(chatId).set({
      'type': 'personal',
      'participants': [teacherId, studentId],
      'teacherId': teacherId,
      'studentId': studentId,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {
        teacherId: 0,
        studentId: 0,
      },
    });

    return chatId;
  }

  /// Send a message in a chat
  /// Both teacher and student can send messages
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is participant
    final chat = await _firestore.collection('chats').doc(chatId).get();
    if (!chat.exists) throw Exception('Chat not found');

    final participants = List<String>.from(chat.data()!['participants']);
    if (!participants.contains(user.uid)) {
      throw Exception('You are not a participant in this chat');
    }

    // Content moderation check
    if (_containsInappropriateContent(text)) {
      throw Exception('Message contains inappropriate content');
    }

    // Send message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': user.uid,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [user.uid],
    });

    // Update last message and unread count
    final otherUserId = participants.firstWhere((id) => id != user.uid);
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });

    // Send notification to the other user
    try {
      final senderDoc = await _firestore.collection('users').doc(user.uid).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['displayName'] ?? 'Someone';
      final senderAvatar = senderData?['avatarUrl'];

      await _notificationService.sendToUser(
        userId: otherUserId,
        title: 'New message from $senderName',
        body: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        data: {
          'type': 'message',
          'chatId': chatId,
          'senderId': user.uid,
          'senderName': senderName,
          'senderAvatar': senderAvatar,
        },
      );
    } catch (e) {
      // Notification failed, but message was sent successfully
      // Don't throw error
    }
  }

  /// Mark messages as read
  Future<void> markAsRead({
    required String chatId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Reset unread count
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.${user.uid}': 0,
    });

    // Update read receipts for messages
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('readBy', whereNotIn: [
          [user.uid]
        ])
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([user.uid]),
      });
    }
    await batch.commit();
  }

  /// Get chats for current user
  Stream<QuerySnapshot> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Get messages for a chat
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Generate consistent chat ID
  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Basic content moderation
  bool _containsInappropriateContent(String text) {
    final lowerText = text.toLowerCase();
    
    // Basic inappropriate keywords list
    final inappropriateKeywords = [
      // Add inappropriate words here
      'spam',
      'scam',
    ];

    return inappropriateKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Delete a chat (teacher only)
  Future<void> deleteChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Verify user is teacher
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception('User not found');

    final userData = userDoc.data()!;
    if (userData['role'] != 'teacher' && userData['isPrincipal'] != true) {
      throw Exception('Only teachers can delete chats');
    }

    // Delete messages
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete chat
    batch.delete(_firestore.collection('chats').doc(chatId));
    await batch.commit();
  }
}
