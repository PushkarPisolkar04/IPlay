import 'package:flutter/material.dart';

/// Custom page route with slide transition from right
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with fade transition
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with scale + fade transition
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleTween = Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOut));
            var fadeAnimation = animation;

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Navigation helpers
extension NavigationExtensions on BuildContext {
  /// Navigate with slide from right
  Future<T?> pushSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideRightRoute(page: page));
  }

  /// Navigate with fade
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadeRoute(page: page));
  }

  /// Navigate with scale + fade
  Future<T?> pushScaleFade<T>(Widget page) {
    return Navigator.of(this).push<T>(ScaleFadeRoute(page: page));
  }

  /// Replace with slide
  Future<T?> pushReplacementSlide<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, dynamic>(SlideRightRoute(page: page));
  }

  /// Replace with fade
  Future<T?> pushReplacementFade<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, dynamic>(FadeRoute(page: page));
  }
}

