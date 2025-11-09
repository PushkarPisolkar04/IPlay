import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for Firebase Cloud Messaging (FCM) notifications
/// Works on Spark plan - no Cloud Functions needed!
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission (iOS primarily)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        // print('User granted provisional notification permission');
      } else {
        // print('User declined or has not accepted notification permission');
        return;
      }

      // Get FCM token
      String? token = await _fcm.getToken();
      
      if (token != null) {
        // Save token to user document
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': Timestamp.now(),
          });
        }
      }

      // Listen for token refresh
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': Timestamp.now(),
          });
        }
      });

      // Handle foreground messages
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // print('Got a message whilst in the foreground!');
        // print('Message data: ${message.data}');

        if (message.notification != null) {
          // print('Message also contained a notification: ${message.notification}');
          _showLocalNotification(message);
        }
      });

      // Handle background message tap
      _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // print('Message clicked!');
        _handleNotificationTap(message);
      });

      // Check if app was opened from notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      // print('Error initializing notifications: $e');
    }
  }

  /// Send notification to specific user (client-side)
  /// Saves notification to Firestore - user will receive it via FCM
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final sender = FirebaseAuth.instance.currentUser;
      
      await _firestore.collection('notifications').add({
        'toUserId': userId,
        'fromUserId': sender?.uid,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'sentAt': Timestamp.now(),
      });

      // Note: Actual FCM push is handled by Firestore client libraries
      // Or you can use a simple background task to poll new notifications
    } catch (e) {
      // print('Error sending notification: $e');
    }
  }

  /// Send notification to multiple users
  Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final batch = _firestore.batch();
    final sender = FirebaseAuth.instance.currentUser;

    for (String userId in userIds) {
      final docRef = _firestore.collection('notifications').doc();
      batch.set(docRef, {
        'toUserId': userId,
        'fromUserId': sender?.uid,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'sentAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  /// Send notification to all classroom students
  Future<void> sendToClassroom({
    required String classroomId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final classroom = await _firestore
        .collection('classrooms')
        .doc(classroomId)
        .get();

    final studentIds = List<String>.from(classroom.data()?['studentIds'] ?? []);
    
    await sendToUsers(
      userIds: studentIds,
      title: title,
      body: body,
      data: {...?data, 'classroomId': classroomId},
    );
  }

  /// Get user's notifications stream
  Stream<QuerySnapshot> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true, 'readAt': Timestamp.now()});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unread = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true, 'readAt': Timestamp.now()});
    }
    await batch.commit();
  }

  /// Show local notification (for foreground messages)
  void _showLocalNotification(RemoteMessage message) {
    // Implement using flutter_local_notifications package if needed
    // For now, just log
    // print('Showing notification: ${message.notification?.title}');
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // print('Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on notification data
    // This can be handled in main.dart with a global navigator key
  }
  
  /// Dispose and clean up subscriptions
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
  }
}
