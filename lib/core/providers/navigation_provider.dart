import 'package:flutter/material.dart';

/// Provider for managing main screen navigation
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void goToLearn() => setIndex(1);
  void goToHome() => setIndex(0);
  void goToGames() => setIndex(2);
  void goToLeaderboard() => setIndex(3);
  void goToProfile() => setIndex(4);
}
