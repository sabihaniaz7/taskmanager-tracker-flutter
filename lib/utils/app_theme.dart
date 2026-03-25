import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines the color palette and utility methods for color selection across the app.
class AppColors {
  /// A collection of pastel colors used for task and habit tracker cards.
  static const List<int> cardPalette = [
    0xFFD8ECFF,
    0xFFFFF3C4,
    0xFFEAE8FF,
    0xFFDDF5E8,
    0xFFFFEDD8,
    0xFFF0E0FF,
    0xFFD8F5F2,
  ];

  // Light Mode Colors
  static const lightBg = Color(0xFFF2F3F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimary = Color(0xFF1C1C2E);
  static const lightSecondary = Color(0xFF6B7080);
  static const lightSubtext = Color(0xFF9098A8);
  static const lightDivider = Color(0xFFE4E6EE);

  // Dark Mode Colors
  static const darkBg = Color(0xFF0F0F18);
  static const darkSurface = Color(0xFF1A1A28);
  static const darkPrimary = Color(0xFFF0F0FF);
  static const darkSecondary = Color(0xFFAAABC0);
  static const darkSubtext = Color(0xFF70728A);
  static const darkDivider = Color(0xFF252538);

  // Semantic Colors
  static const success = Color(0xFF4CAF82);
  static const danger = Color(0xFFE05555);
  static const warning = Color(0xFFE8A030);

  /// Selects an appropriate title color that contrasts with the card background.
  /// 
  /// Fades the color slightly if [isCompleted] is true.
  static Color titleColor(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    final color = theme.textTheme.titleMedium!.color!;
    return isCompleted ? color.withValues(alpha: 0.45) : color;
  }

  /// Selects a body text color based on the current theme brightness.
  static Color bodyColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF9899B8) : const Color(0xFF5A6070);
  }

  /// Selects a date text color based on the current theme brightness.
  static Color dateColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF6870A0) : const Color(0xFF8890A8);
  }

  /// Selects a background color for interactive action buttons on cards.
  static Color actionBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
  }

  /// Selects an icon color for actions based on the current theme brightness.
  static Color actionIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFBBBDD0) : const Color(0xFF50586A);
  }

  /// Selects a subtext color based on the current theme brightness.
  static Color subtextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF8890B0) : const Color(0xFF606878);
  }

  /// Selects a specific label/subtext color for info rows.
  static Color infoLabelColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFB0B8D0) : const Color(0xFF3A4255);
  }
}

/// Centralizes all sizing, spacing, and typography constants used in the app.
class AppSizes {
  // Radius constants
  static const double radiusCard = 18;
  static const double radiusButton = 14;
  static const double radiusSheet = 26;
  static const double radiusSmall = 8;
  static const double radiusChip = 6;

  // Spacing constants
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 20;
  static const double spacingXXL = 28;

  // Typography constants
  static const double fontDisplay = 28;
  static const double fontTitle = 16;
  static const double fontBody = 13;
  static const double fontCaption = 12;
  static const double fontLabel = 11;
  static const double fontMicro = 9;

  // Card specific constants
  static const double cardBarWidth = 10;
  static const double cardBarTextSize = 8.5;
  static const double cardPadding = 16;

  // Icon sizing
  static const double iconM = 18;
  static const double iconS = 14;
  static const double iconL = 26;
}

/// Configures the global [ThemeData] for both Light and Dark modes.
class AppTheme {
  /// The global Light Theme configuration.
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    useMaterial3: true,
    fontFamily: 'Georgia',
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.lightPrimary),
    ),
    dividerColor: AppColors.lightDivider,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.w800,
        color: AppColors.lightPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      titleMedium: TextStyle(
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w700,
        color: AppColors.lightPrimary,
        letterSpacing: -0.2,
      ),
      bodyMedium: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w500,
        color: AppColors.lightSecondary,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: AppSizes.fontLabel,
        fontWeight: FontWeight.w600,
        color: AppColors.lightSubtext,
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontSize: AppSizes.fontLabel,
        fontWeight: FontWeight.w700,
        color: AppColors.lightSubtext,
        letterSpacing: 1.0,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      margin: EdgeInsets.zero,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.lightPrimary,
      unselectedLabelColor: AppColors.lightSubtext,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      hintStyle: const TextStyle(
        color: AppColors.lightSubtext,
        fontSize: AppSizes.fontBody,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: const BorderSide(color: AppColors.lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingL,
        vertical: AppSizes.spacingM,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
      ),
    ),
  );

  /// The global Dark Theme configuration.
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    useMaterial3: true,
    fontFamily: 'Georgia',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.darkPrimary),
    ),
    dividerColor: AppColors.darkDivider,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.w800,
        color: AppColors.darkPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      titleMedium: TextStyle(
        fontSize: AppSizes.fontTitle,
        fontWeight: FontWeight.w700,
        color: AppColors.darkPrimary,
        letterSpacing: -0.2,
      ),
      bodyMedium: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w500,
        color: AppColors.darkSecondary,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: AppSizes.fontLabel,
        fontWeight: FontWeight.w600,
        color: AppColors.darkSubtext,
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontSize: AppSizes.fontLabel,
        fontWeight: FontWeight.w700,
        color: AppColors.darkSubtext,
        letterSpacing: 1.0,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkBg,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      margin: EdgeInsets.zero,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.darkPrimary,
      unselectedLabelColor: AppColors.darkSubtext,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: AppSizes.fontBody,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      hintStyle: const TextStyle(
        color: AppColors.darkSubtext,
        fontSize: AppSizes.fontBody,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: const BorderSide(color: AppColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingL,
        vertical: AppSizes.spacingM,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
      ),
    ),
  );
  /// Shared input decoration for all text fields to ensure visual consistency.
  static InputDecoration commonInputDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingL,
        vertical: AppSizes.spacingM + 2,
      ),
    );
  }
}

/// Manages and persists the user's preferred theme mode (Light/Dark/System).
class ThemeModeNotifier extends ChangeNotifier {
  /// Storage key for persisting the chosen theme mode.
  static const _key = 'theme_mode';
  
  ThemeMode _mode = ThemeMode.system;
  
  /// The current theme mode.
  ThemeMode get mode => _mode;
  
  ThemeModeNotifier(ThemeMode initial) : _mode = initial;

  /// Toggles between Light and Dark mode, persisting the selection.
  /// 
  /// Note: Once toggled, it will not return to [ThemeMode.system] unless manually reset.
  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist();
    notifyListeners();
  }

  /// Saves the current [_mode] name to local storage.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
  }

  /// Loads the persisted theme mode from local storage.
  /// 
  /// Defaults to [ThemeMode.system] if no preference is saved.
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return ThemeMode.system;
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

