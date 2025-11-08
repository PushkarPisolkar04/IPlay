import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for caching content locally
class ContentDatabaseHelper {
  static final ContentDatabaseHelper instance = ContentDatabaseHelper._init();
  static Database? _database;

  ContentDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('content_cache.db');
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
    // Table for cached level content
    await db.execute('''
      CREATE TABLE cached_levels (
        level_id TEXT PRIMARY KEY,
        realm_id TEXT NOT NULL,
        content_json TEXT NOT NULL,
        version TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Table for content version tracking
    await db.execute('''
      CREATE TABLE content_versions (
        realm_id TEXT PRIMARY KEY,
        version TEXT NOT NULL,
        last_checked INTEGER NOT NULL
      )
    ''');

    // Table for offline downloads
    await db.execute('''
      CREATE TABLE offline_realms (
        realm_id TEXT PRIMARY KEY,
        downloaded_at INTEGER NOT NULL,
        total_size INTEGER NOT NULL,
        levels_count INTEGER NOT NULL
      )
    ''');
  }

  // Cache level content
  Future<void> cacheLevelContent({
    required String levelId,
    required String realmId,
    required String contentJson,
    required String version,
    required String updatedAt,
  }) async {
    final db = await database;
    await db.insert(
      'cached_levels',
      {
        'level_id': levelId,
        'realm_id': realmId,
        'content_json': contentJson,
        'version': version,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get cached level content
  Future<Map<String, dynamic>?> getCachedLevel(String levelId) async {
    final db = await database;
    final results = await db.query(
      'cached_levels',
      where: 'level_id = ?',
      whereArgs: [levelId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  // Get all cached levels for a realm
  Future<List<Map<String, dynamic>>> getCachedLevelsForRealm(String realmId) async {
    final db = await database;
    return await db.query(
      'cached_levels',
      where: 'realm_id = ?',
      whereArgs: [realmId],
    );
  }

  // Update content version
  Future<void> updateContentVersion({
    required String realmId,
    required String version,
  }) async {
    final db = await database;
    await db.insert(
      'content_versions',
      {
        'realm_id': realmId,
        'version': version,
        'last_checked': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get content version
  Future<Map<String, dynamic>?> getContentVersion(String realmId) async {
    final db = await database;
    final results = await db.query(
      'content_versions',
      where: 'realm_id = ?',
      whereArgs: [realmId],
    );

    if (results.isEmpty) return null;
    return results.first;
  }

  // Mark realm as downloaded for offline
  Future<void> markRealmDownloaded({
    required String realmId,
    required int totalSize,
    required int levelsCount,
  }) async {
    final db = await database;
    await db.insert(
      'offline_realms',
      {
        'realm_id': realmId,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
        'total_size': totalSize,
        'levels_count': levelsCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Check if realm is downloaded
  Future<bool> isRealmDownloaded(String realmId) async {
    final db = await database;
    final results = await db.query(
      'offline_realms',
      where: 'realm_id = ?',
      whereArgs: [realmId],
    );
    return results.isNotEmpty;
  }

  // Get all downloaded realms
  Future<List<Map<String, dynamic>>> getDownloadedRealms() async {
    final db = await database;
    return await db.query('offline_realms');
  }

  // Delete cached realm
  Future<void> deleteRealmCache(String realmId) async {
    final db = await database;
    await db.delete(
      'cached_levels',
      where: 'realm_id = ?',
      whereArgs: [realmId],
    );
    await db.delete(
      'offline_realms',
      where: 'realm_id = ?',
      whereArgs: [realmId],
    );
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_levels');
    await db.delete('content_versions');
    await db.delete('offline_realms');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
