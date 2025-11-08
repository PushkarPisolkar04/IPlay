import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for haptic feedback
class HapticFeedbackUtil {
  static const String _hapticEnabledKey = 'haptic_feedback_enabled';
  static bool _isEnabled = true;

  /// Initialize haptic feedback settings
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_hapticEnabledKey) ?? true;
  }

  /// Check if haptic feedback is enabled
  static bool get isEnabled => _isEnabled;

  /// Enable or disable haptic feedback
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticEnabledKey, enabled);
  }

  /// Light impact feedback (for button presses)
  static Future<void> lightImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Medium impact feedback (for selections)
  static Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Heavy impact feedback (for important actions)
  static Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Selection click feedback (for toggles and switches)
  static Future<void> selectionClick() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Vibrate feedback (for notifications and alerts)
  static Future<void> vibrate() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Success feedback (for XP gain, level completion)
  static Future<void> success() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Error feedback (for incorrect answers, failures)
  static Future<void> error() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Badge unlock feedback (celebration)
  static Future<void> badgeUnlock() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// XP gain feedback
  static Future<void> xpGain() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Correct answer feedback
  static Future<void> correctAnswer() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }

  /// Incorrect answer feedback
  static Future<void> incorrectAnswer() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // print('Haptic feedback error: $e');
    }
  }
}
