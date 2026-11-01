import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/theme/models/theme_preferences.dart';
import 'package:mac_notes_app/features/theme/presentation/theme_mode_switcher.dart';
import 'package:mac_notes_app/features/theme/providers/theme_provider.dart';
import 'package:mac_notes_app/features/theme/services/theme_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemePreferences Model Tests', () {
    test('serializes and deserializes correctly', () {
      const prefs = ThemePreferences(themeMode: ThemeMode.dark);
      final json = prefs.toJson();
      expect(json['themeMode'], 'dark');

      final deserialized = ThemePreferences.fromJson(json);
      expect(deserialized.themeMode, ThemeMode.dark);
    });

    test('defaults to system mode for invalid or empty input', () {
      final deserialized = ThemePreferences.fromJson({});
      expect(deserialized.themeMode, ThemeMode.system);
    });
  });

  group('ThemeStorageService Tests', () {
    test('defaults to system mode when no preference stored', () async {
      final service = ThemeStorageService();
      final mode = await service.loadThemeMode();
      expect(mode, ThemeMode.system);
    });

    test('persists and loads theme mode', () async {
      final service = ThemeStorageService();
      await service.saveThemeMode(ThemeMode.dark);

      final loaded = await service.loadThemeMode();
      expect(loaded, ThemeMode.dark);
    });
  });

  group('ThemeProvider Tests', () {
    test('initializes with default system mode and updates mode', () async {
      final provider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.isLoaded, true);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('cycleThemeMode cycles through System -> Light -> Dark -> System', () async {
      final provider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.themeMode, ThemeMode.system);

      await provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.light);

      await provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.dark);

      await provider.cycleThemeMode();
      expect(provider.themeMode, ThemeMode.system);
    });
  });

  group('NotesTheme Color Palette Tests', () {
    testWidgets('dynamic colors reflect high contrast pure black in dark mode', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: NotesTheme.lightTheme,
          darkTheme: NotesTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              testContext = context;
              return Container();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(NotesTheme.isDark(testContext), true);
      expect(NotesTheme.editorBackground(testContext), const Color(0xFF000000)); // Pure AMOLED black
      expect(NotesTheme.textPrimary(testContext), const Color(0xFFFFFFFF)); // Crisp white
      expect(NotesTheme.sidebarBackground(testContext), const Color(0xFF0D0D0E));
    });

    testWidgets('dynamic colors reflect crisp light palette in light mode', (tester) async {
      late BuildContext testContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: NotesTheme.lightTheme,
          darkTheme: NotesTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              testContext = context;
              return Container();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(NotesTheme.isDark(testContext), false);
      expect(NotesTheme.editorBackground(testContext), const Color(0xFFFFFFFF)); // Crisp white
      expect(NotesTheme.textPrimary(testContext), const Color(0xFF000000)); // Crisp black
      expect(NotesTheme.sidebarBackground(testContext), const Color(0xFFF2F2F7));
    });
  });

  group('ThemeModeSwitcher Widget Tests', () {
    testWidgets('renders segments and switches theme modes on tap', (tester) async {
      final themeProvider = ThemeProvider();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: MaterialApp(
            theme: NotesTheme.lightTheme,
            darkTheme: NotesTheme.darkTheme,
            home: const Scaffold(
              body: ThemeModeSwitcher(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check that all 3 segment icons exist
      expect(find.byIcon(CupertinoIcons.circle_lefthalf_fill), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.sun_max), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.moon_fill), findsOneWidget);

      // Tap Light Mode
      await tester.tap(find.byIcon(CupertinoIcons.sun_max));
      await tester.pump();
      expect(themeProvider.themeMode, ThemeMode.light);

      // Tap Dark Mode
      await tester.tap(find.byIcon(CupertinoIcons.moon_fill));
      await tester.pump();
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Tap System Mode
      await tester.tap(find.byIcon(CupertinoIcons.circle_lefthalf_fill));
      await tester.pump();
      expect(themeProvider.themeMode, ThemeMode.system);
    });
  });
}
