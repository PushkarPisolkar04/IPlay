import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service for managing sound effects
class SoundService {
  static const String _soundEnabledKey = 'sound_effects_enabled';
  static bool _isEnabled = true;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Initialize sound service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    
    // Set audio player mode for short sound effects
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setVolume(0.5);
  }

  /// Check if sound effects are enabled
  static bool get isEnabled => _isEnabled;

  /// Enable or disable sound effects
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Play a sound effect using system sounds as fallback
  static Future<void> _playSystemSound() async {
    if (!_isEnabled) return;
    
    try {
      // Use system feedback sound as a simple fallback
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently fail if sound can't be played
    }
  }

  /// Play a sound effect with different pitch/duration for variety
  static Future<void> _playTone({required int frequency}) async {
    if (!_isEnabled) return;
    
    try {
      // For now, use system sound as we don't have audio files
      // In production, you would use actual sound files
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently fail if sound can't be played
    }
  }

  /// XP gain sound - short pleasant beep
  static Future<void> playXPGain() async {
    await _playTone(frequency: 800);
  }

  /// Badge unlock sound - celebratory chime
  static Future<void> playBadgeUnlock() async {
    if (!_isEnabled) return;
    
    try {
      // Play multiple tones for celebration effect
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 100));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently fail
    }
  }

  /// Level completion sound - success fanfare
  static Future<void> playLevelComplete() async {
    if (!_isEnabled) return;
    
    try {
      // Play ascending tones for completion
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 80));
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 80));
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Silently fail
    }
  }

  /// Correct answer sound - positive feedback
  static Future<void> playCorrectAnswer() async {
    await _playTone(frequency: 1000);
  }

  /// Incorrect answer sound - negative feedback
  static Future<void> playIncorrectAnswer() async {
    await _playTone(frequency: 400);
  }

  /// Button click sound - subtle tap
  static Future<void> playButtonClick() async {
    await _playSystemSound();
  }

  /// Success sound - achievement unlocked
  static Future<void> playSuccess() async {
    await _playTone(frequency: 900);
  }

  /// Error sound - alert tone
  static Future<void> playError() async {
    await _playTone(frequency: 300);
  }

  /// Notification sound - attention getter
  static Future<void> playNotification() async {
    await _playTone(frequency: 700);
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
