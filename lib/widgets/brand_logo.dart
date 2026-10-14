import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double height;
  const BrandLogo({super.key, this.height = 120});

  static String assetFor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? 'assets/brand/logo_dark.png' : 'assets/brand/logo_light.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetFor(context),
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
