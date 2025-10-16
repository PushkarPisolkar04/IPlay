import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentUser = await _authService.getUserData(uid);
      
      // Update activity
      if (_currentUser != null) {
        await _authService.updateUserActivity(uid);
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String state,
    String? schoolTag,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        state: state,
        schoolTag: schoolTag,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Sign up error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signInWithGoogle();
      return _currentUser != null;
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Google sign in error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOutCompletely();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    }
  }

  Future<void> updateUserRole(String role, String state, String? schoolTag) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateUserData(_currentUser!.uid, {
        'role': role,
        'state': state,
        'schoolTag': schoolTag,
      });

      await loadUserData(_currentUser!.uid);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Update role error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateUserData(_currentUser!.uid, data);
      await loadUserData(_currentUser!.uid);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Update profile error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

