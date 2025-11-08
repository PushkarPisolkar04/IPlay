import 'dart:collection';
import 'package:flutter/material.dart';
import '../../models/badge_model.dart';
import '../../widgets/badge_unlock_animation.dart';

/// Manages queue of badge unlock animations
/// Ensures animations are shown sequentially, not simultaneously
class BadgeAnimationQueue {
  static final BadgeAnimationQueue _instance = BadgeAnimationQueue._internal();
  factory BadgeAnimationQueue() => _instance;
  BadgeAnimationQueue._internal();

  final Queue<BadgeModel> _queue = Queue<BadgeModel>();
  bool _isShowingAnimation = false;

  /// Add badge to animation queue
  void queueBadge(BadgeModel badge) {
    _queue.add(badge);
  }

  /// Add multiple badges to animation queue
  void queueBadges(List<BadgeModel> badges) {
    _queue.addAll(badges);
  }

  /// Show next badge animation if available
  Future<void> showNext(BuildContext context) async {
    if (_isShowingAnimation || _queue.isEmpty) return;

    _isShowingAnimation = true;
    final badge = _queue.removeFirst();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeUnlockAnimation(
        badge: badge,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );

    _isShowingAnimation = false;

    // Show next badge if available
    if (_queue.isNotEmpty && context.mounted) {
      // Small delay between animations
      await Future.delayed(const Duration(milliseconds: 500));
      showNext(context);
    }
  }

  /// Check if there are pending animations
  bool get hasPending => _queue.isNotEmpty;

  /// Get number of pending animations
  int get pendingCount => _queue.length;

  /// Clear all pending animations
  void clear() {
    _queue.clear();
    _isShowingAnimation = false;
  }
}
