import 'package:flutter/material.dart';

/// Một PageRoute tùy chỉnh với hiệu ứng Fade (mờ dần).
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        );
}

/// Một PageRoute tùy chỉnh với hiệu ứng trượt từ phải sang.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlidePageRoute({required this.child, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Bắt đầu từ bên phải (Offset(1.0, 0.0)) và kết thúc ở giữa (Offset.zero)
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOut;

            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Một PageRoute tùy chỉnh với hiệu ứng phóng to và mờ dần.
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ScaleFadePageRoute({required this.child, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}class ModalSlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ModalSlideUpPageRoute({required this.child, RouteSettings? settings})
      : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));
            final scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
                CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic));
            final fadeAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
                CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic));

            return SlideTransition(
              position: slideAnimation,
              child: child,
            );
          },
        );
}
