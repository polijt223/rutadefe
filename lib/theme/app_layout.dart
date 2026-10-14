import 'package:flutter/material.dart';

class AppLayout {
  static const double tabletShortestSide = 600;
  static const double wideWidth = 840;

  static Size sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  static bool isTablet(BuildContext context) =>
      sizeOf(context).shortestSide >= tabletShortestSide;

  static bool isWide(BuildContext context) => sizeOf(context).width >= wideWidth;

  static int seminarColumns(BuildContext context) {
    final width = sizeOf(context).width;
    if (width >= 1200) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isWide(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.all(16);
  }

  static double contentMaxWidth(BuildContext context, [double preferred = 760]) {
    final width = sizeOf(context).width;
    return width < preferred ? width : preferred;
  }
}
