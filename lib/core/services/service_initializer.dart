import 'notification_service.dart';
import 'offline_sync_service.dart';

/// Service Initializer - Manages lazy loading of non-critical services
/// This improves app launch time by deferring initialization of services
/// that aren't needed immediately
class ServiceInitializer {
  static bool _initialized = false;
  
  /// Initialize all non-critical services
  /// Call this after the app has launched and user is on the home screen
  static Future<void> initializeNonCriticalServices() async {
    if (_initialized) return;
    
    try {
      // print('🚀 Initializing non-critical services...');
      
      // Initialize services in parallel for faster loading
      await Future.wait([
        _initializeNotifications(),
        _initializeOfflineSync(),
      ]);
      
      _initialized = true;
      // print('✅ All non-critical services initialized');
    } catch (e) {
      // print('⚠️ Error initializing non-critical services: $e');
    }
  }
  
  /// Initialize notification service
  static Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      // print('✅ Notification service initialized');
    } catch (e) {
      // print('⚠️ Notification service initialization failed: $e');
    }
  }
  
  /// Initialize offline sync service
  static Future<void> _initializeOfflineSync() async {
    try {
      OfflineSyncService.instance.initialize();
      // print('✅ Offline sync service initialized');
    } catch (e) {
      // print('⚠️ Offline sync service initialization failed: $e');
    }
  }
  
  /// Check if services are initialized
  static bool get isInitialized => _initialized;
}
