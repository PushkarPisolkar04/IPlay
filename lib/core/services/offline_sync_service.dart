import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'offline_progress_manager.dart';
import 'badge_service.dart';

/// Service to automatically sync offline progress when device comes online
class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._init();
  
  final OfflineProgressManager _offlineManager = OfflineProgressManager.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeService _badgeService = BadgeService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _wasOffline = false;

  OfflineSyncService._init();

  /// Initialize the sync service
  void initialize() {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    
    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final isOffline = result.contains(ConnectivityResult.none);
    _wasOffline = isOffline;
    
    // If online and has pending progress, sync immediately
    if (!isOffline) {
      final hasPending = await _offlineManager.hasPendingProgress();
      if (hasPending) {
        await syncOfflineProgress();
      }
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isOffline = results.contains(ConnectivityResult.none);
    
    // If we just came online from offline
    if (_wasOffline && !isOffline) {
      // print('Device came online, checking for pending sync...');
      
      // Wait a bit for connection to stabilize
      await Future.delayed(const Duration(seconds: 2));
      
      // Sync offline progress
      await syncOfflineProgress();
    }
    
    _wasOffline = isOffline;
  }

  /// Manually trigger sync
  Future<SyncResult> syncOfflineProgress() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
        totalXP: 0,
      );
    }

    _isSyncing = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return SyncResult(
          success: false,
          message: 'User not authenticated',
          syncedCount: 0,
          totalXP: 0,
        );
      }

      // Get all pending progress
      final pendingProgress = await _offlineManager.getPendingProgress();
      
      if (pendingProgress.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No pending progress to sync',
          syncedCount: 0,
          totalXP: 0,
        );
      }

      // print('Syncing ${pendingProgress.length} offline progress items...');

      int syncedCount = 0;
      int totalXP = 0;
      final List<String> errors = [];

      // Sync each progress item
      for (final progress in pendingProgress) {
        try {
          await _syncSingleProgress(user.uid, progress);
          
          // Mark as synced
          await _offlineManager.markAsSynced(progress['id'] as String);
          
          syncedCount++;
          totalXP += progress['xp_earned'] as int;
        } catch (e) {
          // print('Error syncing progress ${progress['id']}: $e');
          errors.add(e.toString());
          // Continue with next item instead of failing completely
        }
      }

      // Update last sync time
      await _offlineManager.updateLastSyncTime();

      // Check for new badges after sync
      try {
        final newBadges = await _badgeService.checkAndAwardBadges(user.uid);
        if (newBadges.isNotEmpty) {
          // print('New badges unlocked after sync: $newBadges');
        }
      } catch (e) {
        // print('Error checking badges after sync: $e');
      }

      // Clean up old synced progress
      await _offlineManager.clearSyncedProgress();

      return SyncResult(
        success: errors.isEmpty,
        message: errors.isEmpty
            ? 'Successfully synced $syncedCount items'
            : 'Synced $syncedCount items with ${errors.length} errors',
        syncedCount: syncedCount,
        totalXP: totalXP,
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      // print('Error during sync: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
        syncedCount: 0,
        totalXP: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single progress item to Firestore
  Future<void> _syncSingleProgress(
    String userId,
    Map<String, dynamic> progress,
  ) async {
    final contentId = progress['content_id'] as String;
    final contentType = progress['content_type'] as String;
    final xpEarned = progress['xp_earned'] as int;
    final completionPercentage = progress['completion_percentage'] as int;
    final accuracy = progress['accuracy'] as int?;
    final timeSpentSeconds = progress['time_spent_seconds'] as int?;
    final startedAt = progress['started_at'] as int;
    final completedAt = progress['completed_at'] as int?;

    // Create progress document ID
    final progressDocId = '${userId}__$contentId';
    final progressRef = _firestore.collection('progress').doc(progressDocId);

    final batch = _firestore.batch();

    // Check if progress already exists
    final existingDoc = await progressRef.get();

    if (existingDoc.exists) {
      // Update existing progress
      batch.update(progressRef, {
        'xpEarned': FieldValue.increment(xpEarned),
        'attemptsCount': FieldValue.increment(1),
        'lastAttemptAt': Timestamp.now(),
        'completedAt': completedAt != null
            ? Timestamp.fromMillisecondsSinceEpoch(completedAt)
            : FieldValue.serverTimestamp(),
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new progress document
      batch.set(progressRef, {
        'userId': userId,
        'contentId': contentId,
        'contentType': contentType,
        'contentVersion': '1.0.0',
        'status': 'completed',
        'completionPercentage': completionPercentage,
        'xpEarned': xpEarned,
        'attemptsCount': 1,
        'accuracy': accuracy ?? 0,
        'timeSpentSeconds': timeSpentSeconds ?? 0,
        'startedAt': Timestamp.fromMillisecondsSinceEpoch(startedAt),
        'completedAt': completedAt != null
            ? Timestamp.fromMillisecondsSinceEpoch(completedAt)
            : FieldValue.serverTimestamp(),
        'lastAttemptAt': Timestamp.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Update user's total XP
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'totalXP': FieldValue.increment(xpEarned),
      'lastActiveDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If it's a level completion, update progressSummary
    if (contentType == 'level' && contentId.contains('_level_')) {
      final parts = contentId.split('_level_');
      if (parts.length == 2) {
        final realmId = 'realm_${parts[0]}';
        final levelNumber = int.tryParse(parts[1]);
        
        if (levelNumber != null) {
          // Get current user data to update progressSummary
          final userDoc = await userRef.get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            final progressSummary = userData?['progressSummary'] ?? {};
            final realmProgress = progressSummary[realmId] ?? {};
            
            final levelsCompleted = List<int>.from(realmProgress['levelsCompleted'] ?? []);
            if (!levelsCompleted.contains(levelNumber)) {
              levelsCompleted.add(levelNumber);
            }
            
            final totalLevels = realmProgress['totalLevels'] ?? 8;
            final xpEarnedSoFar = (realmProgress['xpEarned'] ?? 0) + xpEarned;
            final isCompleted = levelsCompleted.length >= totalLevels;
            
            batch.update(userRef, {
              'progressSummary.$realmId': {
                'completed': isCompleted,
                'levelsCompleted': levelsCompleted.length,
                'totalLevels': totalLevels,
                'xpEarned': xpEarnedSoFar,
                'lastAccessedAt': FieldValue.serverTimestamp(),
              },
            });
          }
        }
      }
    }

    // Commit the batch
    await batch.commit();

    // print('Synced progress: $contentId, XP: $xpEarned');
  }

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int totalXP;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.totalXP,
    this.errors,
  });
}
