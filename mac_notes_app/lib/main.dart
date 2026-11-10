/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Root application entry point and provider configuration with smooth theme mode interpolation.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/notes_constants.dart';
import 'core/theme/notes_theme.dart';
import 'core/widgets/mac_three_column_scaffold.dart';
import 'features/folders/providers/folder_provider.dart';
import 'features/notes/providers/notes_provider.dart';
import 'features/theme/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacNotesApp());
}

/// Root widget of the Apple Notes macOS replica.
class MacNotesApp extends StatelessWidget {
  const MacNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Notes',
            debugShowCheckedModeBanner: false,
            theme: NotesTheme.lightTheme,
            darkTheme: NotesTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: NotesConstants.themeAnimationDuration,
            themeAnimationCurve: NotesConstants.defaultAnimationCurve,
            home: const MacThreeColumnScaffold(),
          );
        },
      ),
    );
  }
}
