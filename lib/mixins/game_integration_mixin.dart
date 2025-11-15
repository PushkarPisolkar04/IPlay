import 'package:flutter/material.dart';
import '../services/game_integration_service.dart';
import '../widgets/game_ui/xp_gain_animation.dart';

/// Mixin for integrating games with core systems
/// 
/// Usage:
/// ```dart
/// class MyGameScreen extends StatefulWidget {
///   // ...
/// }
/// 
/// class _MyGameScreenState extends State<MyGameScreen> with GameIntegrationMixin {
///   @override
///   String get gameId => 'quiz_master';
///   
///   @override
///   int get baseXP => 50;
///   
///   // ... rest of game implementation
/// }
/// ```
mixin GameIntegrationMixin<T extends StatefulWidget> on State<T> {
  final _gameService = GameIntegrationService();
  
  DateTime? _gameStartTime;
  bool _gameStartLogged = false;

  /// Game identifier (must be implemented by the game screen)
  String get gameId;

  /// Base XP reward for the game (must be implemented by the game screen)
  int get baseXP;

  /// Initialize game integration (call in initState)
  @override
  void initState() {
    super.initState();
    _startGame();
  }

  /// Start game tracking
  Future<void> _startGame() async {
    _gameStartTime = DateTime.now();
    
    if (!_gameStartLogged) {
      await _gameService.logGameStart(gameId);
      _gameStartLogged = true;
    }
  }

  /// Calculate time spent in seconds
  int get _timeSpentSeconds {
    if (_gameStartTime == null) return 0;
    return DateTime.now().difference(_gameStartTime!).inSeconds;
  }

  /// Complete game and award XP
  /// 
  /// Parameters:
  /// - [score]: User's score (0-100)
  /// - [isPerfectScore]: Whether user achieved perfect score
  /// 
  /// Returns the total XP awarded
  Future<int> completeGame({
    required int score,
    bool isPerfectScore = false,
  }) async {
    try {
      final timeSpent = _timeSpentSeconds;

      // Check if first completion
      final isFirstCompletion = await _gameService.isFirstCompletion(gameId);

      // Award XP
      final xpGained = await _gameService.awardGameXP(
        gameId: gameId,
        baseXP: baseXP,
        score: score,
        isPerfectScore: isPerfectScore,
        isFirstCompletion: isFirstCompletion,
      );

      // Save progress
      await _gameService.saveGameProgress(
        gameId: gameId,
        score: score,
        timeSpentSeconds: timeSpent,
        completed: true,
      );

      // Submit to leaderboards
      await _gameService.submitToLeaderboards(
        gameId: gameId,
        score: score,
      );

      // Log analytics
      await _gameService.logGameComplete(
        gameId: gameId,
        score: score,
        timeSpentSeconds: timeSpent,
        isPerfectScore: isPerfectScore,
      );

      // Show XP gain animation
      if (mounted) {
        await showXPGainDialog(
          context,
          xpGained: xpGained,
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );
      }

      return xpGained;
    } catch (e) {
      debugPrint('Error completing game: $e');
      return 0;
    }
  }

  /// Save progress without completing (for partial progress)
  Future<void> saveProgress({
    required int score,
  }) async {
    try {
      await _gameService.saveGameProgress(
        gameId: gameId,
        score: score,
        timeSpentSeconds: _timeSpentSeconds,
        completed: false,
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  /// Log game retry
  Future<void> retryGame() async {
    try {
      await _gameService.logGameRetry(gameId);
      _gameStartTime = DateTime.now();
    } catch (e) {
      debugPrint('Error logging retry: $e');
    }
  }

  /// Log game quit
  Future<void> quitGame({String? reason}) async {
    try {
      await _gameService.logGameQuit(
        gameId: gameId,
        timeSpentSeconds: _timeSpentSeconds,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error logging quit: $e');
    }
  }

  /// Get user's high score for this game
  Future<int> getHighScore() async {
    try {
      final progress = await _gameService.getGameProgress(gameId);
      return progress?.highScore ?? 0;
    } catch (e) {
      debugPrint('Error getting high score: $e');
      return 0;
    }
  }

  /// Get user's rank in leaderboard
  Future<int?> getUserRank(String scope, {String? scopeValue}) async {
    try {
      return await _gameService.getUserRank(
        gameId: gameId,
        scope: scope,
        scopeValue: scopeValue,
      );
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }
}
