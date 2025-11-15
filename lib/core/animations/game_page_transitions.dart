import 'package:flutter/material.dart';
import 'game_animations.dart';

/// Game page transitions for smooth navigation
class GamePageTransitions {
  /// Fade transition route
  static Route<T> fadeTransition<T>({
    required Widget page,
    Duration duration = GameAnimations.normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Slide from bottom transition route
  static Route<T> slideFromBottom<T>({
    required Widget page,
    Duration duration = GameAnimations.normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: GameAnimations.smoothInOut,
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Slide from right transition route
  static Route<T> slideFromRight<T>({
    required Widget page,
    Duration duration = GameAnimations.normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: GameAnimations.smoothInOut,
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Scale transition route with fade
  static Route<T> scaleTransition<T>({
    required Widget page,
    Duration duration = GameAnimations.normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: GameAnimations.smoothInOut,
        ));
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Bounce in transition route
  static Route<T> bounceInTransition<T>({
    required Widget page,
    Duration duration = GameAnimations.slowTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: GameAnimations.bounceIn,
        );
        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Custom game screen transition (slide + fade)
  static Route<T> gameScreenTransition<T>({
    required Widget page,
    Duration duration = GameAnimations.normalTransition,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: GameAnimations.smoothInOut,
        ));
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension on BuildContext for easy navigation with transitions
extension GameNavigationExtensions on BuildContext {
  /// Navigate with fade transition
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.fadeTransition(page: page),
    );
  }

  /// Navigate with slide from bottom transition
  Future<T?> pushWithSlideFromBottom<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.slideFromBottom(page: page),
    );
  }

  /// Navigate with slide from right transition
  Future<T?> pushWithSlideFromRight<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.slideFromRight(page: page),
    );
  }

  /// Navigate with scale transition
  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.scaleTransition(page: page),
    );
  }

  /// Navigate with bounce in transition
  Future<T?> pushWithBounce<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.bounceInTransition(page: page),
    );
  }

  /// Navigate to game screen with custom transition
  Future<T?> pushGameScreen<T>(Widget page) {
    return Navigator.of(this).push<T>(
      GamePageTransitions.gameScreenTransition(page: page),
    );
  }
}
