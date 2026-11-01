import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Authentic color palette and typography matching the native Apple Notes macOS desktop app.
class NotesTheme {
  // Apple Notes Signature Amber / Gold Accent
  static const Color accentGold = Color(0xFFECA825);
  static const Color accentGoldLight = Color(0xFFFFF3D4);
  static const Color accentGoldDark = Color(0xFFD48806);

  // Light Mode Palette
  static const Color lightSidebarBackground = Color(0xFFEBEBF0);
  static const Color lightListBackground = Color(0xFFFFFFFF);
  static const Color lightEditorBackground = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE5E5EA);
  static const Color lightCardHover = Color(0xFFF2F2F7);
  static const Color lightCardSelected = Color(0xFFFEEBBF);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF86868B);
  static const Color lightTextTertiary = Color(0xFFA1A1A6);
  static const Color lightToolbarBackground = Color(0xFFEFEFF4);
  static const Color lightSearchBackground = Color(0xFFE3E3E8);

  // Dark Mode Palette
  static const Color darkSidebarBackground = Color(0xFF1E1E1E);
  static const Color darkListBackground = Color(0xFF252528);
  static const Color darkEditorBackground = Color(0xFF1C1C1E);
  static const Color darkDivider = Color(0xFF38383A);
  static const Color darkCardHover = Color(0xFF2C2C2E);
  static const Color darkCardSelected = Color(0xFF4A3E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);
  static const Color darkToolbarBackground = Color(0xFF262628);
  static const Color darkSearchBackground = Color(0xFF323236);

  /// Check whether the current context is in dark mode
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Dynamic Theme Helpers
  static Color sidebarBackground(BuildContext context) =>
      isDark(context) ? darkSidebarBackground : lightSidebarBackground;

  static Color listBackground(BuildContext context) =>
      isDark(context) ? darkListBackground : lightListBackground;

  static Color editorBackground(BuildContext context) =>
      isDark(context) ? darkEditorBackground : lightEditorBackground;

  static Color divider(BuildContext context) =>
      isDark(context) ? darkDivider : lightDivider;

  static Color cardHover(BuildContext context) =>
      isDark(context) ? darkCardHover : lightCardHover;

  static Color cardSelected(BuildContext context) =>
      isDark(context) ? darkCardSelected : lightCardSelected;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textTertiary(BuildContext context) =>
      isDark(context) ? darkTextTertiary : lightTextTertiary;

  static Color toolbarBackground(BuildContext context) =>
      isDark(context) ? darkToolbarBackground : lightToolbarBackground;

  static Color searchBackground(BuildContext context) =>
      isDark(context) ? darkSearchBackground : lightSearchBackground;

  /// Typography styles matching macOS Apple Notes SF Pro hierarchy
  static TextStyle titleStyle(BuildContext context) => TextStyle(
        fontFamily: '.AppleSystemUIFont',
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: textPrimary(context),
        height: 1.25,
      );

  static TextStyle headingStyle(BuildContext context) => TextStyle(
        fontFamily: '.AppleSystemUIFont',
        fontSize: 19.0,
        fontWeight: FontWeight.w600,
        color: textPrimary(context),
        height: 1.3,
      );

  static TextStyle subheadingStyle(BuildContext context) => TextStyle(
        fontFamily: '.AppleSystemUIFont',
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: textPrimary(context),
        height: 1.35,
      );

  static TextStyle bodyStyle(BuildContext context) => TextStyle(
        fontFamily: '.AppleSystemUIFont',
        fontSize: 14.5,
        fontWeight: FontWeight.normal,
        color: textPrimary(context),
        height: 1.45,
      );

  static TextStyle monoStyle(BuildContext context) => TextStyle(
        fontFamily: 'SF Mono',
        fontSize: 13.5,
        fontWeight: FontWeight.normal,
        color: textPrimary(context),
        backgroundColor: isDark(context) ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        height: 1.4,
      );

  static TextStyle dateHeaderStyle(BuildContext context) => TextStyle(
        fontFamily: '.AppleSystemUIFont',
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: textSecondary(context),
      );

  /// Application ThemeData (Light)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentGold,
      scaffoldBackgroundColor: lightEditorBackground,
      colorScheme: const ColorScheme.light(
        primary: accentGold,
        secondary: accentGold,
        surface: lightListBackground,
        error: CupertinoColors.destructiveRed,
      ),
      dividerColor: lightDivider,
      fontFamily: '.AppleSystemUIFont',
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xE61D1D1F),
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 11.5,
        ),
        waitDuration: Duration(milliseconds: 500),
      ),
    );
  }

  /// Application ThemeData (Dark)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentGold,
      scaffoldBackgroundColor: darkEditorBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentGold,
        surface: darkListBackground,
        error: CupertinoColors.destructiveRed,
      ),
      dividerColor: darkDivider,
      fontFamily: '.AppleSystemUIFont',
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xE6323236),
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 11.5,
        ),
        waitDuration: Duration(milliseconds: 500),
      ),
    );
  }
}
