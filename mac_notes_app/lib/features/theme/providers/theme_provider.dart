// Author: Domonick Mack
// Date: 2026-11-10
// Description: ChangeNotifier provider managing active application theme mode.

import 'package:flutter/material.dart';
import 'package:lusid/features/theme/services/theme_storage_service.dart';

/// Provider managing active application theme appearance (System, Light, Dark).
class ThemeProvider extends ChangeNotifier {
  final ThemeStorageService _storageService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoaded = false;

  ThemeProvider({ThemeStorageService? storageService})
    : _storageService = storageService ?? ThemeStorageService() {
    _initTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  /// Returns whether the effective appearance is currently dark.
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> _initTheme() async {
    _themeMode = await _storageService.loadThemeMode();
    _isLoaded = true;
    notifyListeners();
  }

  /// Sets an explicit theme mode (system, light, or dark) and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(mode);
  }

  /// Cycles through System -> Light -> Dark -> System.
  Future<void> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Toggles between light and dark modes explicitly.
  Future<void> toggleLightDark(BuildContext context) async {
    final currentIsDark = isDarkMode(context);
    final next = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
