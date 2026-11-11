/*
 * Author: Domonick Mack
 * Date: 2026-11-10
 * Description: Unit and widget tests for NotesUtils, FolderProvider, NotesProvider, and Lusid fluid UI transitions.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/core/utils/notes_utils.dart';
import 'package:lusid/core/utils/platform_layout.dart';
import 'package:lusid/core/widgets/about_notes_dialog.dart';
import 'package:lusid/features/auth_sync/presentation/sync_settings_dialog.dart';
import 'package:lusid/features/folders/providers/folder_provider.dart';
import 'package:lusid/features/notes/presentation/notes_gallery_view.dart';
import 'package:lusid/features/notes/providers/notes_provider.dart';
import 'package:lusid/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotesUtils Tests', () {
    test('extractTitle gets first non-empty line and strips markdown', () {
      expect(
        NotesUtils.extractTitle('# My Meeting Notes\nSome body text'),
        'My Meeting Notes',
      );
      expect(NotesUtils.extractTitle('   Clean Title   \nBody'), 'Clean Title');
      expect(
        NotesUtils.extractTitle('', defaultTitle: 'Empty Note'),
        'Empty Note',
      );
    });

    test('extractSnippet gets subsequent text', () {
      expect(
        NotesUtils.extractSnippet('Title\nFirst line of body\nSecond line'),
        'First line of body',
      );
      expect(NotesUtils.extractSnippet('Title Only'), 'No additional text');
    });

    test('formatListDate handles today, yesterday, and dates', () {
      final now = DateTime.now();
      expect(NotesUtils.formatListDate(now), contains(':'));
      expect(
        NotesUtils.formatListDate(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });
  });

  group('FolderProvider Tests', () {
    test('initializes with default system folders', () async {
      final provider = FolderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.folders.isNotEmpty, true);
      expect(provider.selectedFolderId, NotesConstants.allNotesFolderId);
      expect(provider.quickNotesFolder?.id, NotesConstants.quickNotesFolderId);
    });

    test('creates and deletes custom folder', () async {
      final provider = FolderProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final newFolder = await provider.createFolder('Design Specs');
      expect(provider.folders.any((f) => f.id == newFolder.id), true);
      expect(provider.selectedFolderId, newFolder.id);

      await provider.deleteFolder(newFolder.id);
      expect(provider.folders.any((f) => f.id == newFolder.id), false);
    });
  });

  group('NotesProvider Tests', () {
    test('loads initial seed notes and selects first note', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.allNotes.isNotEmpty, true);
      expect(provider.selectedNote, isNotNull);
      expect(provider.selectedNote?.isPinned, true);
    });

    test('creates new note and updates content', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(
        folderId: NotesConstants.defaultNotesFolderId,
      );
      expect(provider.selectedNoteId, note.id);

      provider.updateNoteText(
        note.id,
        'Sprint Planning\nDiscussing tasks for tomorrow',
      );
      expect(provider.selectedNote?.title, 'Sprint Planning');
      expect(provider.selectedNote?.body, 'Discussing tasks for tomorrow');
    });

    test('toggles pin and checklist items', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = provider.allNotes.first;
      final initialPinned = note.isPinned;
      await provider.togglePin(note.id);
      expect(
        provider.allNotes.firstWhere((n) => n.id == note.id).isPinned,
        !initialPinned,
      );

      await provider.addChecklist(note.id, text: 'Test Checklist Item');
      final updatedNote = provider.allNotes.firstWhere((n) => n.id == note.id);
      expect(
        updatedNote.checklists.any((c) => c.text == 'Test Checklist Item'),
        true,
      );
    });
  });

  group('Widget Tests', () {
    testWidgets('LusidApp renders without error', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const LusidApp());
      // Pump frames to allow async providers to load
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LusidApp), findsOneWidget);
    });

    testWidgets(
      'LusidApp animates sidebar toggle and view mode transitions smoothly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const LusidApp());
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        // Toggle sidebar collapse and pump mid-animation to verify zero overflow
        await tester.tap(find.byIcon(CupertinoIcons.sidebar_left));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 250));

        // Switch to Gallery View and pump through transition
        await tester.tap(find.byIcon(CupertinoIcons.square_grid_2x2));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(NotesGalleryView), findsOneWidget);

        // Switch back to List View
        await tester.tap(find.byIcon(CupertinoIcons.list_bullet));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 250));
      },
    );

    testWidgets('Sidebar displays AppIconBadge and opens AboutLusidDialog', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const LusidApp());
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(AppIconBadge), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('about_notes_btn')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(AboutLusidDialog), findsOneWidget);
      expect(find.text(NotesConstants.appName), findsOneWidget);
      expect(find.text(NotesConstants.appVersion), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AboutLusidDialog), findsNothing);
    });

    testWidgets(
      'iPad Portrait (820x1180) and Compact Slide-Over (540x900) adapt without overflow',
      (WidgetTester tester) async {
        expect(PlatformLayout.sizeClassForWidth(1180), ScreenSizeClass.wide);
        expect(PlatformLayout.sizeClassForWidth(820), ScreenSizeClass.medium);
        expect(PlatformLayout.sizeClassForWidth(540), ScreenSizeClass.compact);

        // Test iPad Portrait (820x1180)
        tester.view.physicalSize = const Size(820, 1180);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const LusidApp());
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        // Dismiss slide-over drawer via scrim
        await tester.tap(find.byKey(const ValueKey('sidebar_drawer_scrim')));
        await tester.pump(const Duration(milliseconds: 250));

        // Test Compact Slide-Over (540x900)
        tester.view.physicalSize = const Size(540, 900);
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const ValueKey('compact_back_to_list_btn')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('compact_back_to_list_btn')),
        );
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byKey(const ValueKey('compact_list_view')), findsOneWidget);
      },
    );

    testWidgets(
      'Toolbar opens SyncSettingsDialog when tapping Cloud Sync icon',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const LusidApp());
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        await tester.tap(find.byIcon(CupertinoIcons.cloud));
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.byType(SyncSettingsDialog), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(SyncSettingsDialog), findsNothing);
      },
    );
  });
}
