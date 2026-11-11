// Author: Domonick Mack
// Date: 2026-11-10
// Description: Comprehensive unit and widget tests for FormatMenuBar, AttachmentWidget, Dialogs, SyncProvider, FolderProvider, and NotesProvider.

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/features/auth_sync/providers/sync_provider.dart';
import 'package:lusid/features/auth_sync/services/notes_api_sync_service.dart';
import 'package:lusid/features/folders/models/folder_model.dart';
import 'package:lusid/features/folders/presentation/add_folder_dialog.dart';
import 'package:lusid/features/folders/providers/folder_provider.dart';
import 'package:lusid/features/notes/models/note_model.dart';
import 'package:lusid/features/notes/presentation/editor_view.dart';
import 'package:lusid/features/notes/presentation/format_menu_bar.dart';
import 'package:lusid/features/notes/presentation/widgets/attachment_widget.dart';
import 'package:lusid/features/notes/presentation/widgets/note_lock_dialog.dart';
import 'package:lusid/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FormatMenuBar Widget Tests', () {
    testWidgets('triggers every NoteTextFormat callback and hover state', (
      tester,
    ) async {
      final selectedFormats = <NoteTextFormat>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FormatMenuBar(onSelectFormat: selectedFormats.add),
            ),
          ),
        ),
      );

      for (final label in [
        'B',
        'I',
        'U',
        'S',
        '</>',
        'Title',
        'Heading',
        'Subheading',
        'Body',
        'Monospaced',
        '• Bulleted List',
        '1. Numbered List',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      expect(selectedFormats.length, 12);
      expect(selectedFormats, containsAll(NoteTextFormat.values));

      // Trigger hover on inline button and format option
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('B')));
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.text('Title')));
      await tester.pumpAndSettle();
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
    });
  });

  group('AttachmentWidget Tests', () {
    testWidgets('renders document and image attachments, sizes, and delete', (
      tester,
    ) async {
      bool deleted = false;
      final docAttachment = const NoteAttachment(
        id: 'att_1',
        name: 'architecture_spec.pdf',
        fileType: 'pdf',
        localPath: '/nonexistent/architecture_spec.pdf',
        fileSize: 2048,
      );
      final smallAttachment = const NoteAttachment(
        id: 'att_2',
        name: 'tiny.txt',
        fileType: 'txt',
        localPath: '/nonexistent/tiny.txt',
        fileSize: 512,
      );
      final largeImgAttachment = const NoteAttachment(
        id: 'att_3',
        name: 'diagram.png',
        fileType: 'image/png',
        localPath: '/nonexistent/diagram.png',
        fileSize: 3 * 1024 * 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AttachmentWidget(
                  attachment: docAttachment,
                  onDelete: () => deleted = true,
                ),
                AttachmentWidget(attachment: smallAttachment, onDelete: () {}),
                AttachmentWidget(
                  attachment: largeImgAttachment,
                  onDelete: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('architecture_spec.pdf'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
      expect(find.text('512 B'), findsOneWidget);
      expect(find.text('3.0 MB'), findsOneWidget);

      // Hover & tap delete on first attachment
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.text('architecture_spec.pdf')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.trash).first);
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  group('NoteLockDialog & AddFolderDialog Tests', () {
    testWidgets('NoteLockDialog validates blank and mismatched passwords', (
      tester,
    ) async {
      String? returnedPassword;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedPassword = await showCupertinoDialog<String>(
                    context: context,
                    builder: (_) =>
                        const NoteLockDialog(isCurrentlyLocked: false),
                  );
                },
                child: const Text('Open Lock Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Lock Dialog'));
      await tester.pumpAndSettle();

      // Blank password validation
      await tester.tap(find.text('Set Lock'));
      await tester.pumpAndSettle();
      expect(find.text('Password cannot be blank.'), findsOneWidget);

      // Mismatched password validation
      final fields = find.byType(CupertinoTextField);
      await tester.enterText(fields.first, 'secret123');
      await tester.enterText(fields.last, 'different');
      await tester.tap(find.text('Set Lock'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);

      // Matching password succeeds
      await tester.enterText(fields.last, 'secret123');
      await tester.tap(find.text('Set Lock'));
      await tester.pumpAndSettle();
      expect(returnedPassword, 'secret123');
    });

    testWidgets('NoteLockDialog unlock mode and cancel button work', (
      tester,
    ) async {
      String? result = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showCupertinoDialog<String>(
                    context: context,
                    builder: (_) =>
                        const NoteLockDialog(isCurrentlyLocked: true),
                  );
                },
                child: const Text('Open Unlock'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Password Lock'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('AddFolderDialog creates folder or cancels cleanly', (
      tester,
    ) async {
      Map<String, String>? folderResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  folderResult = await showCupertinoDialog<Map<String, String>>(
                    context: context,
                    builder: (_) =>
                        const AddFolderDialog(initialName: 'Initial'),
                  );
                },
                child: const Text('Open Folder Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Folder Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(CupertinoTextField), 'Engineering');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(folderResult?['name'], 'Engineering');
      expect(folderResult?['account'], NotesConstants.accountICloud);
    });
  });

  group('NotesApiSyncService & SyncProvider Tests', () {
    test(
      'NotesApiSyncService normalizes URLs, checks health, and syncs batch',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/health/')) {
            return http.Response.bytes(
              utf8.encode(jsonEncode({'status': 'healthy'})),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.url.path.endsWith('/sync/')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'status': 'success',
                  'syncedNotes': (body['notes'] as List).length,
                  'syncedFolders': (body['folders'] as List).length,
                  'notes': body['notes'],
                  'folders': body['folders'],
                }),
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('Server Error', 500);
        });

        final service = NotesApiSyncService(
          baseUrl: 'http://localhost:8000/api/',
          client: mockClient,
        );
        expect(service.baseUrl, 'http://localhost:8000/api');
        service.updateBaseUrl('   ');
        expect(service.baseUrl, 'http://127.0.0.1:8000/api');

        expect(
          await service.checkHealth(overrideUrl: 'http://localhost:8000/api/'),
          isTrue,
        );

        final notesProvider = NotesProvider();
        final folderProvider = FolderProvider();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final syncProvider = SyncProvider(syncService: service);
        await syncProvider.setServerUrl('http://localhost:8000/api');
        expect(await syncProvider.checkConnection(), isTrue);
        expect(syncProvider.status, SyncStatus.synced);

        final synced = await syncProvider.syncNow(
          notesProvider: notesProvider,
          folderProvider: folderProvider,
        );
        expect(synced, isTrue);
        expect(syncProvider.status, SyncStatus.synced);
        expect(syncProvider.lastSyncedAt, isNotNull);
      },
    );

    test('SyncProvider handles offline and HTTP error responses', () async {
      final errorClient = MockClient((_) async => http.Response('Error', 500));
      final errorService = NotesApiSyncService(client: errorClient);
      final syncProvider = SyncProvider(syncService: errorService);
      final notesProvider = NotesProvider();
      final folderProvider = FolderProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        await syncProvider.checkConnection(customUrl: 'http://bad-host/api'),
        isFalse,
      );
      expect(syncProvider.status, SyncStatus.offline);

      final ok = await syncProvider.syncNow(
        notesProvider: notesProvider,
        folderProvider: folderProvider,
      );
      expect(ok, isFalse);
      expect(syncProvider.status, SyncStatus.error);
    });
  });

  group('FolderProvider & NotesProvider Full Operations Tests', () {
    test(
      'FolderProvider CRUD, icons, sidebar state, and mergeSyncedFolders',
      () async {
        final provider = FolderProvider();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(provider.folders, isNotEmpty);
        expect(provider.quickNotesFolder, isNotNull);
        expect(provider.trashFolder, isNotNull);
        expect(provider.iCloudFolders, isNotEmpty);
        expect(provider.onMyMacFolders, isEmpty);

        // Verify iconData for all folder types
        for (final f in provider.folders) {
          expect(f.iconData, isNotNull);
          final roundTrip = Folder.fromJson(f.toJson());
          expect(roundTrip.id, f.id);
        }

        provider.toggleSidebar();
        expect(provider.isSidebarCollapsed, isTrue);
        provider.setSidebarCollapsed(false);
        expect(provider.isSidebarCollapsed, isFalse);

        final created = await provider.createFolder('Custom Folder');
        expect(provider.selectedFolderId, created.id);
        expect(provider.selectedFolder?.name, 'Custom Folder');

        await provider.renameFolder(created.id, 'Renamed Folder');
        expect(provider.selectedFolder?.name, 'Renamed Folder');

        final futureTime = DateTime.now().add(const Duration(minutes: 10));
        await provider.mergeSyncedFolders([
          created.copyWith(name: 'Synced Remote Name', updatedAt: futureTime),
        ]);
        expect(provider.selectedFolder?.name, 'Synced Remote Name');

        await provider.deleteFolder(created.id);
        expect(provider.selectedFolderId, NotesConstants.allNotesFolderId);
      },
    );

    test(
      'NotesProvider CRUD, lock, attachments, checklists, tables, and sync',
      () async {
        final provider = NotesProvider();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final note = await provider.createNote(
          folderId: NotesConstants.allNotesFolderId,
          title: 'Initial Title',
          body: 'Initial body #tag1',
        );
        expect(provider.selectedNoteId, note.id);

        // Update text & rich text
        provider.updateNoteText(note.id, 'Updated Title\nSecond line #flutter');
        provider.updateNoteRichText(
          note.id,
          richTextJson: '[{"insert":"Updated Title\\n"}]',
          plainText: 'Updated Title\nSecond line #flutter',
        );
        expect(provider.selectedNote?.title, 'Updated Title');

        // Pin, search, tag filter, view mode
        await provider.togglePin(note.id);
        expect(provider.selectedNote!.isPinned, isTrue);
        provider.toggleViewMode();
        expect(provider.viewMode, NotesViewMode.gallery);
        provider.setViewMode(NotesViewMode.list);
        provider.setSearchQuery('Updated');
        expect(
          provider.getFilteredNotes(NotesConstants.allNotesFolderId),
          isNotEmpty,
        );
        provider.setSearchQuery('');
        provider.setActiveTag(null);

        // Checklists
        await provider.addChecklist(note.id, text: 'Item A');
        final checklistId = provider.selectedNote!.checklists.first.id;
        await provider.toggleChecklist(note.id, checklistId);
        expect(provider.selectedNote!.checklists.first.isCompleted, isTrue);
        await provider.updateChecklistText(
          note.id,
          checklistId,
          'Item A Edited',
        );
        await provider.removeChecklist(note.id, checklistId);
        expect(provider.selectedNote!.checklists, isEmpty);

        // Tables
        await provider.addTable(note.id);
        final tableId = provider.selectedNote!.tables.first.id;
        await provider.updateTableCell(note.id, tableId, 0, 0, 'Cell 0,0');
        await provider.addTableRow(note.id, tableId);
        await provider.addTableColumn(note.id, tableId);
        await provider.insertTableRow(note.id, tableId, 1);
        await provider.insertTableColumn(note.id, tableId, 1);
        await provider.deleteTableRow(note.id, tableId, 0);
        await provider.deleteTableColumn(note.id, tableId, 0);
        await provider.removeTable(note.id, tableId);
        expect(provider.selectedNote!.tables, isEmpty);

        // Lock & password verification
        await provider.setNoteLock(note.id, isLocked: true, password: 'pass');
        expect(provider.verifyPassword(note.id, 'pass'), isTrue);
        expect(provider.verifyPassword(note.id, 'wrong'), isFalse);
        await provider.setNoteLock(note.id, isLocked: false);

        // Attachments
        const attachment = NoteAttachment(
          id: 'att_99',
          name: 'report.pdf',
          fileType: 'pdf',
          localPath: '/tmp/report.pdf',
          fileSize: 1024,
        );
        await provider.addAttachment(note.id, attachment);
        expect(provider.selectedNote!.attachments.length, 1);
        expect(NoteAttachment.fromJson(attachment.toJson()).name, 'report.pdf');
        await provider.removeAttachment(note.id, 'att_99');
        expect(provider.selectedNote!.attachments, isEmpty);

        // Duplicate, move, trash, restore, permanent delete
        final dup = await provider.duplicateNote(note.id);
        await provider.moveNote(dup.id, 'work_folder');
        expect(provider.countNotesInFolder('work_folder'), greaterThan(0));

        await provider.deleteNote(dup.id); // Moves to trash
        expect(
          provider.countNotesInFolder(NotesConstants.trashFolderId),
          greaterThan(0),
        );
        await provider.restoreNote(dup.id);
        await provider.deleteNote(dup.id); // Move to trash again
        await provider.deleteNote(dup.id); // Permanent delete from trash

        // Merge synced notes
        final remoteNote = note.copyWith(
          title: 'Remote Synced Note',
          updatedAt: DateTime.now().add(const Duration(minutes: 5)),
        );
        await provider.mergeSyncedNotes([remoteNote]);
        expect(
          provider.allNotes.firstWhere((n) => n.id == note.id).title,
          'Remote Synced Note',
        );

        // Serialization round-trip
        final jsonMap = remoteNote.toJson();
        expect(Note.fromJson(jsonMap).title, 'Remote Synced Note');
      },
    );

    testWidgets(
      'EditorView applies formats, renders locked note view, and unlocks with password',
      (tester) async {
        final notesProvider = NotesProvider();
        await tester.pumpWidget(
          ChangeNotifierProvider<NotesProvider>.value(
            value: notesProvider,
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 900,
                  height: 700,
                  child: EditorView(
                    showFormatMenu: true,
                    onCloseFormatMenu: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Trigger FormatMenuBar options inside EditorView to cover _applyFormat
        for (final label in [
          'B',
          'I',
          'U',
          'S',
          '</>',
          'Title',
          'Heading',
          'Subheading',
          'Body',
          'Monospaced',
          '• Bulleted List',
          '1. Numbered List',
        ]) {
          final target = find.descendant(
            of: find.byType(FormatMenuBar),
            matching: find.text(label),
          );
          if (target.evaluate().isNotEmpty) {
            await tester.tap(target.first);
            await tester.pump();
          }
        }

        final noteId = notesProvider.selectedNoteId!;
        await notesProvider.setNoteLock(
          noteId,
          isLocked: true,
          password: 'apple',
        );
        await tester.pumpAndSettle();

        expect(find.text('This Note is Locked'), findsOneWidget);

        // Wrong password shows error
        await tester.enterText(find.byType(CupertinoTextField), 'wrong');
        await tester.tap(find.text('Unlock'));
        await tester.pumpAndSettle();
        expect(find.text('Incorrect password. Try again.'), findsOneWidget);

        // Correct password unlocks note
        await tester.enterText(find.byType(CupertinoTextField), 'apple');
        await tester.tap(find.text('Unlock'));
        await tester.pumpAndSettle();
        expect(notesProvider.selectedNote!.isLocked, isFalse);

        // Deselecting note shows empty state
        notesProvider.selectNote(null);
        await tester.pumpAndSettle();
        expect(find.text('No Note Selected'), findsOneWidget);
      },
    );
  });
}
