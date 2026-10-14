import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';

class BrandLoadingScreen extends StatelessWidget {
  final String caption;

  const BrandLoadingScreen({
    super.key,
    this.caption = 'Preparando tu camino',
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? AppTheme.darkBg : AppTheme.cream,
          image: DecorationImage(
            image: AssetImage(dark ? 'assets/home/bg_dark.jpg' : 'assets/home/bg_light.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(height: 168),
                  const SizedBox(height: 28),
                  Text(
                    'Ruta de Fe',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: dark ? Colors.white : const Color(0xFF3F4A24),
                        ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.gold,
                        backgroundColor: colors.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.3,
                      color: colors.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
