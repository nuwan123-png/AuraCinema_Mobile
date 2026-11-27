import 'package:flutter/material.dart';
import 'theme/aura_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AuraCinemaApp());
}

class AuraCinemaApp extends StatelessWidget {
  const AuraCinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: auraThemeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'AuraCinema',
          debugShowCheckedModeBanner: false,
          theme: AuraAppTheme.lightTheme,
          darkTheme: AuraAppTheme.darkTheme,
          themeMode: currentMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}