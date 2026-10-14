import 'package:flutter/material.dart';

class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Curve emphasized = Curves.easeOutCubic;

  static Duration staggered(int index, {int stepMs = 45, int capMs = 280}) {
    return Duration(milliseconds: 280 + (index * stepMs).clamp(0, capMs));
  }
}

class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.emphasized,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.04, 0),
      ).animate(outgoing),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.88).animate(outgoing),
        child: FadeTransition(
          opacity: incoming,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.07, 0.012),
              end: Offset.zero,
            ).animate(incoming),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.975, end: 1).animate(incoming),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
