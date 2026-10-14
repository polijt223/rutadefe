import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack> {
  late int _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.index;
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previous = oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forward = widget.index >= _previous;
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _TabPane(
            active: i == widget.index,
            forward: forward,
            child: widget.children[i],
          ),
      ],
    );
  }
}

class _TabPane extends StatelessWidget {
  final bool active;
  final bool forward;
  final Widget child;

  const _TabPane({
    required this.active,
    required this.forward,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      opacity: active ? 1 : 0,
      child: AnimatedSlide(
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
        offset: active ? Offset.zero : Offset(forward ? 0.04 : -0.04, 0),
        child: child,
      ),
    );
  }
}
