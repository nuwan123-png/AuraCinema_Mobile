import 'package:flutter/material.dart';

/// Default cinema vibe එකට Option A (Dark Glassmorphism) set කරලා තියෙන්නේ
final ValueNotifier<ThemeMode> auraThemeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

@immutable
class AuraGlassColors extends ThemeExtension<AuraGlassColors> {
  final List<Color> backgroundGradient;
  final Color ambientGlowPrimary;
  final Color ambientGlowSecondary;
  final Color glassFill;
  final Color glassBorder;
  final Color cardSurface;
  final Color modalSurface;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;

  const AuraGlassColors({
    required this.backgroundGradient,
    required this.ambientGlowPrimary,
    required this.ambientGlowSecondary,
    required this.glassFill,
    required this.glassBorder,
    required this.cardSurface,
    required this.modalSurface,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
  });

  // Option A — Dark Glassmorphism (Default Cinema Theme)
  static const dark = AuraGlassColors(
    backgroundGradient: [
      Color(0xFF0B0E17),
      Color(0xFF121726),
      Color(0xFF0B0E17),
    ],
    ambientGlowPrimary: Color(0x338B5CF6),   // Electric Violet glow
    ambientGlowSecondary: Color(0x26FF9F1C), // Warm Amber glow
    glassFill: Color(0x0FFFFFFF),            // rgba(255, 255, 255, 0.06)
    glassBorder: Color(0x1FFFFFFF),          // rgba(255, 255, 255, 0.12)
    cardSurface: Color(0xCC141824),          // Translucent dark card
    modalSurface: Color(0xFF131724),         // Dialog / BottomSheet bg
    primaryAccent: Color(0xFF8B5CF6),        // Electric Violet
    secondaryAccent: Color(0xFFFF9F1C),      // Warm Amber (Brand Continuity)
    textPrimary: Color(0xFFF4F4F8),
    textSecondary: Color(0xFF9CA3AF),
  );

  // Option B — Light Glassmorphism
  static const light = AuraGlassColors(
    backgroundGradient: [
      Color(0xFFF5F3FF),
      Color(0xFFEDE9FE),
    ],
    ambientGlowPrimary: Color(0x336D28D9),   // Soft Indigo mist
    ambientGlowSecondary: Color(0x2EF472B6), // Soft Coral-Pink mist
    glassFill: Color(0x8CFFFFFF),            // rgba(255, 255, 255, 0.55)
    glassBorder: Color(0xCCFFFFFF),          // rgba(255, 255, 255, 0.80)
    cardSurface: Color(0xB3FFFFFF),          // Translucent white card
    modalSurface: Color(0xFFF8F7FF),         // Light Dialog / BottomSheet bg
    primaryAccent: Color(0xFF6D28D9),        // Deep Indigo / Violet
    secondaryAccent: Color(0xFFF472B6),      // Soft Coral-Pink
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
  );

  @override
  AuraGlassColors copyWith({
    List<Color>? backgroundGradient,
    Color? ambientGlowPrimary,
    Color? ambientGlowSecondary,
    Color? glassFill,
    Color? glassBorder,
    Color? cardSurface,
    Color? modalSurface,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AuraGlassColors(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      ambientGlowPrimary: ambientGlowPrimary ?? this.ambientGlowPrimary,
      ambientGlowSecondary: ambientGlowSecondary ?? this.ambientGlowSecondary,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      cardSurface: cardSurface ?? this.cardSurface,
      modalSurface: modalSurface ?? this.modalSurface,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  AuraGlassColors lerp(ThemeExtension<AuraGlassColors>? other, double t) {
    if (other is! AuraGlassColors) return this;
    return AuraGlassColors(
      backgroundGradient: [
        Color.lerp(backgroundGradient.first, other.backgroundGradient.first, t)!,
        Color.lerp(backgroundGradient.last, other.backgroundGradient.last, t)!,
      ],
      ambientGlowPrimary:
          Color.lerp(ambientGlowPrimary, other.ambientGlowPrimary, t)!,
      ambientGlowSecondary:
          Color.lerp(ambientGlowSecondary, other.ambientGlowSecondary, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

class AuraAppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0E17),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFFF9F1C),
      surface: Color(0xFF0B0E17),
    ),
    extensions: const [AuraGlassColors.dark],
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F3FF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6D28D9),
      secondary: Color(0xFFF472B6),
      surface: Color(0xFFF5F3FF),
    ),
    extensions: const [AuraGlassColors.light],
  );
}