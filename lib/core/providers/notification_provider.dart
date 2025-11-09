import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Provider for managing notification state with caching
class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  Timer? _cacheTimer;
  
  // Cache settings
  static const Duration _cacheDuration = Duration(minutes: 5);
  DateTime? _lastFetch;
  
  int get unreadCount => _unreadCount;
  
  /// Initialize notification listener
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Set up real-time listener with caching
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            _unreadCount = snapshot.docs.length;
            _lastFetch = DateTime.now();
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error listening to notifications: $error');
          },
        );
  }
  
  /// Refresh notification count manually
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();
      
      _unreadCount = snapshot.docs.length;
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      
      // Count will update automatically via listener
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      
      // Count will update automatically via listener
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
  
  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _cacheTimer?.cancel();
    super.dispose();
  }
}
