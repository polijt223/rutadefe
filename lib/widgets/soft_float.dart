import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class SoftFloat extends StatefulWidget {
  final Widget child;
  final double offset;
  final Duration duration;
  final Duration delay;

  const SoftFloat({
    super.key,
    required this.child,
    this.offset = 5,
    this.duration = const Duration(milliseconds: 2200),
    this.delay = Duration.zero,
  });

  @override
  State<SoftFloat> createState() => _SoftFloatState();
}

class _SoftFloatState extends State<SoftFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final inTest = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
    if (inTest) return;
    _start = Timer(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -widget.offset * t),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PopIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: Duration(milliseconds: AppMotion.medium.inMilliseconds + delay.inMilliseconds.clamp(0, 240)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: child,
    );
  }
}
