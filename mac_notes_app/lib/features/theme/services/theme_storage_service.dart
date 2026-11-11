// Author: Domonick Mack
// Date: 2026-11-10
// Description: Storage service for persisting theme appearance mode locally.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting theme preferences locally.
class ThemeStorageService {
  static const String themeModeKey = 'apple_notes_theme_mode_v1';

  /// Loads the persisted theme mode, defaulting to system appearance.
  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(themeModeKey);
      if (modeName == null || modeName.isEmpty) {
        return ThemeMode.system;
      }

      return ThemeMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      return ThemeMode.system;
    }
  }

  /// Persists the selected theme mode.
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themeModeKey, mode.name);
    } catch (_) {
      // Graceful error recovery
    }
  }
}
