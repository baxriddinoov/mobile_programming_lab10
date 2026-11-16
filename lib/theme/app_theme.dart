import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryContainerColor = Color(0xFFEEF2FF); // Indigo 50
  static const Color onPrimaryContainerColor = Color(0xFF312E81); // Indigo 900
  static const Color secondaryColor = Color(0xFF0891B2); // Cyan 600
  static const Color secondaryContainerColor = Color(0xFFECFEFF); // Cyan 50
  static const Color onSecondaryContainerColor = Color(0xFF164E63); // Cyan 900
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceDimColor = Color(0xFFF8FAFC); // Slate 50 background
  static const Color onSurfaceColor = Color(0xFF0F172A); // Slate 900
  static const Color onSurfaceVariantColor = Color(0xFF64748B); // Slate 500
  static const Color outlineColor = Color(0xFFE2E8F0); // Slate 200
  static const Color outlineVariantColor = Color(0xFFCBD5E1); // Slate 300
  static const Color errorColor = Color(0xFFDC2626); // Red 600
  static const Color errorContainerColor = Color(0xFFFEF2F2); // Red 50
  static const Color onErrorContainerColor = Color(0xFF991B1B); // Red 800

  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 10.0;

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: onPrimaryContainerColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainerColor,
      onSecondaryContainer: onSecondaryContainerColor,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      onSurfaceVariant: onSurfaceVariantColor,
      outline: outlineColor,
      outlineVariant: outlineVariantColor,
      error: errorColor,
      onError: Colors.white,
      errorContainer: errorContainerColor,
      onErrorContainer: onErrorContainerColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDimColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: outlineColor, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: outlineColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainerColor,
        labelStyle: const TextStyle(
          color: onPrimaryContainerColor,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryContainerColor,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: onSurfaceVariantColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: onSurfaceVariantColor,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: outlineColor,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: onSurfaceVariantColor,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: TextStyle(
          color: onSurfaceColor,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: onSurfaceVariantColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
