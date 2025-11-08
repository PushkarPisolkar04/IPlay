import 'package:shared_preferences/shared_preferences.dart';

class AppTourService {
  static const String _tourCompletedKey = 'app_tour_completed';
  static const String _featureTourPrefix = 'feature_tour_';

  Future<bool> isTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourCompletedKey) ?? false;
  }

  Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  Future<bool> isFeatureTourCompleted(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_featureTourPrefix$featureId') ?? false;
  }

  Future<void> markFeatureTourCompleted(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_featureTourPrefix$featureId', true);
  }

  Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, false);
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_featureTourPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
