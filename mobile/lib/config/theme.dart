import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C3DE0);   // deep violet
  static const Color primaryLight = Color(0xFF9B70F5);
  static const Color primaryDark  = Color(0xFF4A1DB8);
  static const Color accentColor  = Color(0xFFFF6B35);   // warm orange-coral
  static const Color accentLight  = Color(0xFFFF8C5A);

  static const Color secondaryColor = Color(0xFF00C9A7); // teal-mint success
  static const Color successColor   = Color(0xFF10B981);
  static const Color warningColor   = Color(0xFFF59E0B);
  static const Color errorColor     = Color(0xFFEF4444);
  static const Color infoColor      = Color(0xFF3B82F6);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color backgroundColor = Color(0xFFF7F5FF); // very faint lavender bg
  static const Color surfaceColor    = Color(0xFFFFFFFF);
  static const Color cardColor       = Color(0xFFFFFFFF);
  static const Color textPrimary     = Color(0xFF1A1033);
  static const Color textSecondary   = Color(0xFF5E5878);
  static const Color textLight       = Color(0xFFADA7C0);
  static const Color dividerColor    = Color(0xFFEDE9F8);
  static const Color inputFill       = Color(0xFFF2EFFC);

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF110E22);
  static const Color darkSurface    = Color(0xFF1C1730);
  static const Color darkCard       = Color(0xFF261F42);
  static const Color darkDivider    = Color(0xFF2E2650);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight, Color(0xFFB57BFF)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3D1BA6), primaryColor, Color(0xFF8050E8)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFFFF8E53)],
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.10),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, -8),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: primaryColor.withOpacity(0.30),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEDE8FF),
        onPrimaryContainer: primaryDark,
        secondary: accentColor,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFFFEDE5),
        onSecondaryContainer: const Color(0xFF8B3000),
        tertiary: secondaryColor,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFD9FFF6),
        onTertiaryContainer: const Color(0xFF004D3A),
        error: errorColor,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFEEEE),
        onErrorContainer: const Color(0xFF7A0000),
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: inputFill,
        onSurfaceVariant: textSecondary,
        outline: dividerColor,
        outlineVariant: const Color(0xFFE4DEFF),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: darkSurface,
        onInverseSurface: Colors.white,
        inversePrimary: primaryLight,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.4),
          disabledForegroundColor: Colors.white60,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: textLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: textLight,
        suffixIconColor: textLight,
        floatingLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 0,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontSize: 57, fontWeight: FontWeight.w800, color: textPrimary),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontSize: 45, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400, color: textLight),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelMedium: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500, color: textLight),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return dividerColor;
        }),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: Colors.white,
        secondary: accentLight,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF5C2200),
        onSecondaryContainer: accentLight,
        tertiary: secondaryColor,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFF003D2E),
        onTertiaryContainer: secondaryColor,
        error: errorColor,
        onError: Colors.white,
        errorContainer: const Color(0xFF5A0000),
        onErrorContainer: errorColor,
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest: darkCard,
        onSurfaceVariant: Colors.white70,
        outline: darkDivider,
        outlineVariant: darkCard,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Colors.white,
        onInverseSurface: textPrimary,
        inversePrimary: primaryColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  // ── Utility: Category Colors ───────────────────────────────────────────────
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':  return const Color(0xFFFF6B35);
      case 'bar':         return const Color(0xFF7C3AED);
      case 'cafe':        return const Color(0xFF92400E);
      case 'food truck':  return const Color(0xFF059669);
      case 'bakery':      return const Color(0xFFDB2777);
      case 'pizza':       return const Color(0xFFDC2626);
      case 'sushi':       return const Color(0xFF0284C7);
      case 'fast food':   return const Color(0xFFD97706);
      default:            return primaryColor;
    }
  }

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':  return Icons.restaurant_rounded;
      case 'bar':         return Icons.local_bar_rounded;
      case 'cafe':        return Icons.coffee_rounded;
      case 'food truck':  return Icons.delivery_dining_rounded;
      case 'bakery':      return Icons.cake_rounded;
      case 'pizza':       return Icons.local_pizza_rounded;
      case 'sushi':       return Icons.set_meal_rounded;
      case 'fast food':   return Icons.fastfood_rounded;
      default:            return Icons.storefront_rounded;
    }
  }
}
