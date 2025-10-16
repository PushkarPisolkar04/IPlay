import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// User state provider
class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userModel != null;
  bool get isStudent => _userModel?.role == 'student';
  bool get isTeacher => _userModel?.role == 'teacher';
  bool get isPrincipal => _userModel?.isPrincipal ?? false;

  /// Initialize user data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await loadUserProfile(user.uid);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('UserProvider initialization error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user profile from Firestore
  Future<void> loadUserProfile(String uid) async {
    try {
      _userModel = await _authService.getUserProfile(uid);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      notifyListeners();
    }
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String state,
    String? schoolTag,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create Firebase Auth user
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      // Create Firestore profile
      await _authService.createUserProfile(
        uid: userCredential.user!.uid,
        email: email,
        role: role,
        displayName: displayName,
        state: state,
        schoolTag: schoolTag,
      );

      // Load user profile
      await loadUserProfile(userCredential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      await loadUserProfile(userCredential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      // Check if user profile exists
      final profile = await _authService.getUserProfile(userCredential.user!.uid);
      
      if (profile == null) {
        // New user - needs to complete profile
        _userModel = null;
        _isLoading = false;
        notifyListeners();
        return false; // Needs profile setup
      }

      await loadUserProfile(userCredential.user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_userModel == null) return;

    try {
      await _authService.updateUserProfile(_userModel!.uid, data);
      await loadUserProfile(_userModel!.uid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add XP
  Future<void> addXP(int xp) async {
    if (_userModel == null) return;

    try {
      final newXP = _userModel!.totalXP + xp;
      await updateProfile({'totalXP': newXP});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update streak
  Future<void> updateStreak() async {
    if (_userModel == null) return;

    final now = DateTime.now();
    final lastActive = _userModel!.lastActiveDate;
    final hoursDiff = now.difference(lastActive).inHours;

    int newStreak = _userModel!.currentStreak;

    if (hoursDiff <= 48) {
      // Within grace period
      if (now.day != lastActive.day) {
        newStreak++;
      }
    } else {
      // Streak broken
      newStreak = 1;
    }

    try {
      await updateProfile({
        'currentStreak': newStreak,
        'lastActiveDate': now,
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

