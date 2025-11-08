import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for IPlay app with aggressive caching strategy
/// 
/// Cache durations:
/// - Static content (images, icons): 24 hours
/// - User data (avatars, profiles): 1 hour
/// - Leaderboards: 1 hour
class IPlayCacheManager {
  // Static content cache (24 hours)
  static final CacheManager staticContentCache = CacheManager(
    Config(
      'static_content_cache',
      stalePeriod: const Duration(hours: 24),
      maxNrOfCacheObjects: 200,
    ),
  );

  // User data cache (1 hour)
  static final CacheManager userDataCache = CacheManager(
    Config(
      'user_data_cache',
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 100,
    ),
  );

  // Leaderboard cache (1 hour)
  static final CacheManager leaderboardCache = CacheManager(
    Config(
      'leaderboard_cache',
      stalePeriod: const Duration(hours: 1),
      maxNrOfCacheObjects: 50,
    ),
  );

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    await Future.wait([
      staticContentCache.emptyCache(),
      userDataCache.emptyCache(),
      leaderboardCache.emptyCache(),
    ]);
  }

  /// Clear specific cache
  static Future<void> clearCache(CacheManager manager) async {
    await manager.emptyCache();
  }
}
