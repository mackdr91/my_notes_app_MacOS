import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/notes_theme.dart';
import 'core/widgets/mac_three_column_scaffold.dart';
import 'features/folders/providers/folder_provider.dart';
import 'features/notes/providers/notes_provider.dart';

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
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: MaterialApp(
        title: 'Notes',
        debugShowCheckedModeBanner: false,
        theme: NotesTheme.lightTheme,
        darkTheme: NotesTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MacThreeColumnScaffold(),
      ),
    );
  }
}
