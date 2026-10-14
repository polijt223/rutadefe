import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const FadeSlideIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: AppMotion.medium.inMilliseconds + delay.clamp(0, 280)),
      curve: AppMotion.emphasized,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
