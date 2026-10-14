import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class LivingIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final double size;
  final Color? color;

  const LivingIcon({
    super.key,
    required this.icon,
    this.active = false,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$icon-$active'),
      tween: Tween(begin: active ? 0.82 : 1, end: 1),
      duration: active ? AppMotion.medium : AppMotion.fast,
      curve: active ? Curves.easeOutBack : AppMotion.emphasized,
      builder: (context, value, child) {
        return Transform.scale(
          scale: active ? 1.08 * value : value,
          child: Transform.rotate(
            angle: active ? (1 - value) * 0.35 : 0,
            child: child,
          ),
        );
      },
      child: Icon(icon, size: size, color: color),
    );
  }
}
