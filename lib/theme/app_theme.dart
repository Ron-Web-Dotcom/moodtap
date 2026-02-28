import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern premium theme for MoodTap with clean blue accent colors
/// Inspired by modern travel app aesthetics with rounded cards and gradients
class AppTheme {
  AppTheme._();

  // Primary blue accent - clean modern blue
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF42A5F5);

  // Secondary - deeper blue
  static const Color secondaryLight = Color(0xFF1565C0);
  static const Color secondaryDark = Color(0xFF1976D2);

  // Accent - sky blue
  static const Color accentBlue = Color(0xFF64B5F6);
  static const Color accentLightBlue = Color(0xFFE3F2FD);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Card colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252525);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Gradient colors
  static const Color gradientStart = Color(0xFF2196F3);
  static const Color gradientEnd = Color(0xFF1565C0);

  // Mood colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFEF9A9A);

  // Shadow
  static const Color shadowLight = Color(0x1A2196F3);
  static const Color shadowDark = Color(0x40000000);

  // Divider
  static const Color dividerLight = Color(0xFFE8EDF2);
  static const Color dividerDark = Color(0xFF2A2A2A);

  // On-color variants
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFFFFFFFF);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1A2E);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF000000);

  /// Light theme with modern premium aesthetics
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: accentLightBlue,
      onPrimaryContainer: secondaryLight,
      secondary: secondaryLight,
      onSecondary: onSecondaryLight,
      secondaryContainer: accentLightBlue,
      onSecondaryContainer: secondaryLight,
      tertiary: accentBlue,
      onTertiary: onSecondaryLight,
      tertiaryContainer: accentLightBlue,
      onTertiaryContainer: secondaryLight,
      error: errorLight,
      onError: onErrorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textSecondaryLight,
      outline: dividerLight,
      outlineVariant: Color(0xFFDDE3EA),
      shadow: shadowLight,
      scrim: Color(0x40000000),
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: dividerLight,

    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimaryLight,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: textPrimaryLight),
    ),

    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shadowColor: shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: onPrimaryLight,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryLight,
        backgroundColor: primaryLight,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        side: BorderSide(color: primaryLight, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    textTheme: _buildTextTheme(isLight: true),

    inputDecorationTheme: InputDecorationThemeData(
      fillColor: Color(0xFFF0F4F8),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: textSecondaryLight,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: textSecondaryLight.withValues(alpha: 0.6),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return primaryLight.withValues(alpha: 0.6);
        return textSecondaryLight.withValues(alpha: 0.3);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryLight),
      side: BorderSide(color: dividerLight, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryLight;
        return textSecondaryLight;
      }),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimaryLight,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        height: 1.6,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryLight,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      behavior: SnackBarBehavior.floating,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: textSecondaryLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: accentLightBlue,
      selectedColor: primaryLight,
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.transparent,
    ),

    dividerTheme: DividerThemeData(color: dividerLight, thickness: 1, space: 1),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: accentLightBlue,
    ),
  );

  /// Dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: Color(0xFF1565C0),
      onPrimaryContainer: Color(0xFFBBDEFB),
      secondary: secondaryDark,
      onSecondary: onSecondaryDark,
      secondaryContainer: Color(0xFF1565C0),
      onSecondaryContainer: Color(0xFFBBDEFB),
      tertiary: accentBlue,
      onTertiary: onSecondaryDark,
      tertiaryContainer: Color(0xFF1565C0),
      onTertiaryContainer: Color(0xFFBBDEFB),
      error: errorDark,
      onError: onErrorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textSecondaryDark,
      outline: dividerDark,
      outlineVariant: Color(0xFF333333),
      shadow: shadowDark,
      scrim: Color(0x80000000),
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: dividerDark,

    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimaryDark,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: textPrimaryDark),
    ),

    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: onPrimaryDark,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: onPrimaryDark,
        backgroundColor: primaryDark,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textTheme: _buildTextTheme(isLight: false),

    inputDecorationTheme: InputDecorationThemeData(
      fillColor: Color(0xFF2A2A2A),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: primaryDark, width: 2),
      ),
      labelStyle: GoogleFonts.inter(color: textSecondaryDark, fontSize: 15),
      hintStyle: GoogleFonts.inter(
        color: textSecondaryDark.withValues(alpha: 0.6),
        fontSize: 15,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryDark;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return primaryDark.withValues(alpha: 0.6);
        return textSecondaryDark.withValues(alpha: 0.3);
      }),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryDark,
      unselectedLabelColor: textSecondaryDark,
      indicatorColor: primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: Color(0xFF2A2A2A),
      contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      behavior: SnackBarBehavior.floating,
    ),

    dividerTheme: DividerThemeData(color: dividerDark, thickness: 1, space: 1),
  );

  /// Build text theme using Inter font
  static TextTheme _buildTextTheme({required bool isLight}) {
    final textPrimary = isLight ? textPrimaryLight : textPrimaryDark;
    final textSecondary = isLight ? textSecondaryLight : textSecondaryDark;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -1.0,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.1,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
