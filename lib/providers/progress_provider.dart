import 'package:flutter/foundation.dart';
import '../core/models/progress_model.dart';
import '../core/models/realm_model.dart';
import '../models/level_model.dart';
import '../services/firestore_service.dart';

class ProgressProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<ProgressModel> _userProgress = [];
  List<RealmModel> _realms = [];
  final Map<String, List<LevelModel>> _realmLevels = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<ProgressModel> get userProgress => _userProgress;
  List<RealmModel> get realms => _realms;
  Map<String, List<LevelModel>> get realmLevels => _realmLevels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadRealms() {
    _firestoreService.getRealms().listen((realms) {
      _realms = realms;
      notifyListeners();
      
      // Load levels for each realm
      for (final realm in realms) {
        loadLevelsForRealm(realm.id);
      }
    });
  }

  void loadLevelsForRealm(String realmId) {
    _firestoreService.getLevelsForRealm(realmId).listen((levels) {
      _realmLevels[realmId] = levels;
      notifyListeners();
    });
  }

  void loadUserProgress(String userId) {
    _firestoreService.getUserAllProgress(userId).listen((progress) {
      _userProgress = progress;
      notifyListeners();
    });
  }

  Future<void> saveProgress(ProgressModel progress) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.saveProgress(progress);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Save progress error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProgressModel?> getUserProgress(String userId, String levelId) async {
    try {
      return await _firestoreService.getUserProgress(userId, levelId);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Get progress error: $e');
      }
      return null;
    }
  }

  ProgressModel? getProgressForLevel(String levelId) {
    try {
      return _userProgress.firstWhere((p) => p.levelId == levelId);
    } catch (e) {
      return null;
    }
  }

  int getRealmCompletedLevels(String realmId) {
    return _userProgress
        .where((p) => p.realmId == realmId && p.isCompleted)
        .length;
  }

  double getRealmProgress(String realmId) {
    final levels = _realmLevels[realmId];
    if (levels == null || levels.isEmpty) return 0.0;
    
    final completed = getRealmCompletedLevels(realmId);
    return completed / levels.length;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

