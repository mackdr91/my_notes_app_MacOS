import 'package:flutter/material.dart';

/// User theme preferences model for Apple Notes replica.
class ThemePreferences {
  final ThemeMode themeMode;

  const ThemePreferences({
    this.themeMode = ThemeMode.system,
  });

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
      };

  factory ThemePreferences.fromJson(Map<String, dynamic> json) {
    final modeStr = json['themeMode'] as String? ?? 'system';
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ThemeMode.system,
    );
    return ThemePreferences(themeMode: mode);
  }

  ThemePreferences copyWith({ThemeMode? themeMode}) {
    return ThemePreferences(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
