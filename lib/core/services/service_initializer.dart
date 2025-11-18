import 'notification_service.dart';

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
      // Initialize notification service
      await _initializeNotifications();
      
      _initialized = true;
    } catch (e) {
      // Silently handle initialization errors
    }
  }
  
  /// Initialize notification service
  static Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
    } catch (e) {
      // Silently handle notification initialization errors
    }
  }
  
  /// Check if services are initialized
  static bool get isInitialized => _initialized;
}
