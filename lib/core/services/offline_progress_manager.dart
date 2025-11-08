import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Manager for tracking progress offline and syncing when online
class OfflineProgressManager {
  static final OfflineProgressManager instance = OfflineProgressManager._init();
  static Database? _database;

  OfflineProgressManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_progress.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Table for offline progress
    await db.execute('''
      CREATE TABLE offline_progress (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content_id TEXT NOT NULL,
        content_type TEXT NOT NULL,
        xp_earned INTEGER NOT NULL,
        quiz_score INTEGER,
        total_questions INTEGER,
        completion_percentage INTEGER NOT NULL,
        accuracy INTEGER,
        time_spent_seconds INTEGER,
        started_at INTEGER NOT NULL,
        completed_at INTEGER,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // Table for tracking sync status
    await db.execute('''
      CREATE TABLE sync_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync_at INTEGER,
        pending_count INTEGER DEFAULT 0,
        total_unsaved_xp INTEGER DEFAULT 0
      )
    ''');

    // Initialize sync status
    await db.insert('sync_status', {
      'last_sync_at': DateTime.now().millisecondsSinceEpoch,
      'pending_count': 0,
      'total_unsaved_xp': 0,
    });
  }

  /// Save progress locally when offline
  Future<void> saveProgressLocally({
    required String userId,
    required String contentId,
    required String contentType,
    required int xpEarned,
    int? quizScore,
    int? totalQuestions,
    required int completionPercentage,
    int? accuracy,
    int? timeSpentSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    try {
      final db = await database;
      final id = '${userId}__${contentId}__${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(
        'offline_progress',
        {
          'id': id,
          'user_id': userId,
          'content_id': contentId,
          'content_type': contentType,
          'xp_earned': xpEarned,
          'quiz_score': quizScore,
          'total_questions': totalQuestions,
          'completion_percentage': completionPercentage,
          'accuracy': accuracy,
          'time_spent_seconds': timeSpentSeconds ?? 0,
          'started_at': (startedAt ?? DateTime.now()).millisecondsSinceEpoch,
          'completed_at': completedAt?.millisecondsSinceEpoch,
          'synced': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update sync status
      await _updateSyncStatus();

      // print('Progress saved locally: $contentId, XP: $xpEarned');
    } catch (e) {
      // print('Error saving progress locally: $e');
      rethrow;
    }
  }

  /// Get all pending (unsynced) progress
  Future<List<Map<String, dynamic>>> getPendingProgress() async {
    try {
      final db = await database;
      return await db.query(
        'offline_progress',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      // print('Error getting pending progress: $e');
      return [];
    }
  }

  /// Get pending progress count
  Future<int> getPendingCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM offline_progress WHERE synced = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      // print('Error getting pending count: $e');
      return 0;
    }
  }

  /// Get total unsaved XP
  Future<int> getTotalUnsavedXP() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(xp_earned) as total FROM offline_progress WHERE synced = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      // print('Error getting total unsaved XP: $e');
      return 0;
    }
  }

  /// Mark progress as synced
  Future<void> markAsSynced(String id) async {
    try {
      final db = await database;
      await db.update(
        'offline_progress',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update sync status
      await _updateSyncStatus();
    } catch (e) {
      // print('Error marking progress as synced: $e');
      rethrow;
    }
  }

  /// Update sync status table
  Future<void> _updateSyncStatus() async {
    try {
      final db = await database;
      final pendingCount = await getPendingCount();
      final totalUnsavedXP = await getTotalUnsavedXP();

      await db.update(
        'sync_status',
        {
          'pending_count': pendingCount,
          'total_unsaved_xp': totalUnsavedXP,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      // print('Error updating sync status: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final db = await database;
      final results = await db.query(
        'sync_status',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (results.isEmpty) return null;
      return results.first;
    } catch (e) {
      // print('Error getting sync status: $e');
      return null;
    }
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    try {
      final db = await database;
      await db.update(
        'sync_status',
        {'last_sync_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [1],
      );
    } catch (e) {
      // print('Error updating last sync time: $e');
    }
  }

  /// Clear all synced progress (cleanup)
  Future<void> clearSyncedProgress() async {
    try {
      final db = await database;
      await db.delete(
        'offline_progress',
        where: 'synced = ?',
        whereArgs: [1],
      );
    } catch (e) {
      // print('Error clearing synced progress: $e');
    }
  }

  /// Clear all offline progress (for testing/reset)
  Future<void> clearAllProgress() async {
    try {
      final db = await database;
      await db.delete('offline_progress');
      await _updateSyncStatus();
    } catch (e) {
      // print('Error clearing all progress: $e');
    }
  }

  /// Check if there's pending progress to sync
  Future<bool> hasPendingProgress() async {
    final count = await getPendingCount();
    return count > 0;
  }

  /// Get offline progress for a specific user
  Future<List<Map<String, dynamic>>> getUserOfflineProgress(String userId) async {
    try {
      final db = await database;
      return await db.query(
        'offline_progress',
        where: 'user_id = ? AND synced = ?',
        whereArgs: [userId, 0],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      // print('Error getting user offline progress: $e');
      return [];
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
