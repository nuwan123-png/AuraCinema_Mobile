import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/aura_theme.dart';

class AuraGradientScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;

  const AuraGradientScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glass.backgroundGradient,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _AmbientGlowOrb(color: glass.ambientGlowPrimary, size: 280),
          ),
          Positioned(
            bottom: 90,
            right: -70,
            child:
                _AmbientGlowOrb(color: glass.ambientGlowSecondary, size: 250),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: appBar,
            body: body,
            bottomNavigationBar: bottomNavigationBar,
          ),
        ],
      ),
    );
  }
}

class _AmbientGlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? customFill;
  final Color? customBorder;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 22,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.customFill,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    final panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: customFill ?? glass.glassFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: customBorder ?? glass.glassBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

class AuraThemeToggleButton extends StatelessWidget {
  const AuraThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = Theme.of(context).extension<AuraGlassColors>()!;

    return Tooltip(
      message: isDark ? 'Switch to Light Glass' : 'Switch to Dark Glass',
      child: GlassPanel(
        borderRadius: 12,
        blur: 16,
        padding: const EdgeInsets.all(7),
        onTap: () {
          auraThemeNotifier.value =
              isDark ? ThemeMode.light : ThemeMode.dark;
        },
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
          color: glass.secondaryAccent,
        ),
      ),
    );
  }
}