import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to check for app updates
/// Compares current app version with latest version in Firestore
class AppUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if an update is available
  /// Returns a map with 'updateAvailable', 'latestVersion', 'currentVersion', 'updateUrl', 'forceUpdate'
  Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      if (kDebugMode) {
        print('Current version: $currentVersion ($buildNumber)');
      }

      // Get latest version from Firestore
      final doc = await _firestore.collection('app_config').doc('version').get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('No version document found in Firestore');
        }
        return {
          'updateAvailable': false,
          'currentVersion': currentVersion,
        };
      }

      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String? ?? currentVersion;
      final minRequiredVersion = data['minRequiredVersion'] as String? ?? '0.0.0';
      final updateUrl = data['updateUrl'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';

      // Compare versions
      final isUpdateAvailable = _isNewerVersion(latestVersion, currentVersion);
      final isForceUpdate = _isNewerVersion(currentVersion, minRequiredVersion) == false;

      if (kDebugMode) {
        print('Latest version: $latestVersion');
        print('Update available: $isUpdateAvailable');
        print('Force update: $isForceUpdate');
      }

      return {
        'updateAvailable': isUpdateAvailable,
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'minRequiredVersion': minRequiredVersion,
        'updateUrl': updateUrl,
        'releaseNotes': releaseNotes,
        'forceUpdate': isForceUpdate,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
      return {
        'updateAvailable': false,
        'error': e.toString(),
      };
    }
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.2.4")
  /// Returns true if newVersion is newer than currentVersion
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      if (kDebugMode) {
        print('Error comparing versions: $e');
      }
      return false;
    }
  }

  /// Create/update version document in Firestore (admin only)
  /// This should be called when releasing a new version
  Future<void> setLatestVersion({
    required String latestVersion,
    required String minRequiredVersion,
    String? updateUrl,
    String? releaseNotes,
  }) async {
    try {
      await _firestore.collection('app_config').doc('version').set({
        'latestVersion': latestVersion,
        'minRequiredVersion': minRequiredVersion,
        'updateUrl': updateUrl ?? '',
        'releaseNotes': releaseNotes ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Version updated to $latestVersion');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting latest version: $e');
      }
      rethrow;
    }
  }
}
