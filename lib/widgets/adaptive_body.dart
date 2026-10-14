import 'package:flutter/material.dart';
import '../theme/app_layout.dart';

class AdaptiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool padded;
  final Alignment alignment;

  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padded = true,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppLayout.contentMaxWidth(context, maxWidth),
            maxHeight: double.infinity,
          ),
          child: padded
              ? Padding(padding: AppLayout.pagePadding(context), child: child)
              : child,
        ),
      ),
    );
  }
}
