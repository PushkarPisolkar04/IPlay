import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for handling app crashes and state recovery
/// Saves app state before crashes and restores it on restart
class CrashRecoveryService {
  static final CrashRecoveryService _instance = CrashRecoveryService._internal();
  factory CrashRecoveryService() => _instance;
  CrashRecoveryService._internal();

  static const String _appStateKey = 'app_state_backup';
  static const String _lastCrashKey = 'last_crash_timestamp';
  static const String _crashCountKey = 'crash_count';

  /// Initialize Firebase Crashlytics
  static Future<void> initialize() async {
    try {
      // Crashlytics is not fully supported on web, so skip initialization
      if (kIsWeb) {
        // print('Crashlytics not available on web platform');
        return;
      }

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Enable Crashlytics collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Check if app recovered from crash
      await _checkCrashRecovery();
    } catch (e) {
      // Silently fail if Crashlytics is not available
      // print('Crashlytics initialization failed: $e');
    }
  }

  /// Check if app crashed previously and handle recovery
  static Future<void> _checkCrashRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCrash = prefs.getInt(_lastCrashKey);
      
      if (lastCrash != null) {
        final crashTime = DateTime.fromMillisecondsSinceEpoch(lastCrash);
        final now = DateTime.now();
        
        // If crash was within last 5 minutes, consider it a recent crash
        if (now.difference(crashTime).inMinutes < 5) {
          final crashCount = prefs.getInt(_crashCountKey) ?? 0;
          await prefs.setInt(_crashCountKey, crashCount + 1);
          
          // Log crash recovery event (only on non-web platforms)
          if (!kIsWeb) {
            await FirebaseCrashlytics.instance.log(
              'App recovered from crash. Crash count: ${crashCount + 1}'
            );
          }
        } else {
          // Reset crash count if it's been a while
          await prefs.setInt(_crashCountKey, 0);
        }
        
        // Clear last crash timestamp
        await prefs.remove(_lastCrashKey);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Save current app state for recovery
  Future<void> saveAppState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(state);
      await prefs.setString(_appStateKey, stateJson);
      
      // Also save timestamp
      await prefs.setInt(
        _lastCrashKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // print('Error saving app state: $e');
    }
  }

  /// Restore app state after crash
  Future<Map<String, dynamic>?> restoreAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_appStateKey);
      
      if (stateJson != null) {
        final state = jsonDecode(stateJson) as Map<String, dynamic>;
        
        // Clear saved state after restoration
        await prefs.remove(_appStateKey);
        
        return state;
      }
    } catch (e) {
      // print('Error restoring app state: $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to restore app state',
      );
    }
    return null;
  }

  /// Get crash count
  Future<int> getCrashCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_crashCountKey) ?? 0;
  }

  /// Reset crash count
  Future<void> resetCrashCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_crashCountKey, 0);
  }

  /// Check if app has crashed multiple times recently
  Future<bool> hasFrequentCrashes() async {
    final crashCount = await getCrashCount();
    return crashCount >= 3;
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Set custom key-value pairs for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      // Silently fail
    }
  }

  /// Log message to crash reports
  Future<void> log(String message) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      // Silently fail
    }
  }

  /// Record non-fatal error
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Force a crash (for testing only)
  void forceCrash() {
    if (kIsWeb) return;
    FirebaseCrashlytics.instance.crash();
  }
}

/// Mixin for screens that want to save/restore state
mixin CrashRecoveryMixin {
  /// Override this to provide state to save
  Map<String, dynamic> getStateToSave() {
    return {};
  }

  /// Override this to restore state
  void restoreState(Map<String, dynamic> state) {
    // Implement in subclass
  }

  /// Save current state
  Future<void> saveState() async {
    final state = getStateToSave();
    if (state.isNotEmpty) {
      await CrashRecoveryService().saveAppState(state);
    }
  }

  /// Restore saved state
  Future<void> loadSavedState() async {
    final state = await CrashRecoveryService().restoreAppState();
    if (state != null) {
      restoreState(state);
    }
  }
}

/// Widget wrapper for automatic state saving
class CrashRecoveryWrapper {
  /// Wrap a function with crash recovery
  static Future<T?> wrap<T>(
    Future<T> Function() function, {
    String? context,
    T? fallbackValue,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      await CrashRecoveryService().recordError(
        error,
        stackTrace,
        reason: context,
        fatal: false,
      );
      return fallbackValue;
    }
  }

  /// Wrap a synchronous function with crash recovery
  static T? wrapSync<T>(
    T Function() function, {
    String? context,
    T? fallbackValue,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      CrashRecoveryService().recordError(
        error,
        stackTrace,
        reason: context,
        fatal: false,
      );
      return fallbackValue;
    }
  }
}
