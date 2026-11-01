import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/utils/markdown_converter.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/code_block_widget.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        return null;
      }
      return null;
    });
  });

  group('NoteCodeBlock Model Tests', () {
    test('JSON serialization and deserialization roundtrip', () {
      final codeBlock = NoteCodeBlock(
        id: 'code-1',
        language: 'python',
        code: 'def hello():\n    return "world"',
      );

      final json = codeBlock.toJson();
      expect(json['id'], 'code-1');
      expect(json['language'], 'python');
      expect(json['code'], 'def hello():\n    return "world"');

      final reconstructed = NoteCodeBlock.fromJson(json);
      expect(reconstructed.id, codeBlock.id);
      expect(reconstructed.language, codeBlock.language);
      expect(reconstructed.code, codeBlock.code);
    });

    test('copyWith updates specified fields', () {
      final original = NoteCodeBlock(
        id: 'code-1',
        language: 'dart',
        code: 'void main() {}',
      );

      final updated = original.copyWith(
        language: 'javascript',
        code: 'console.log("hello");',
      );

      expect(updated.id, 'code-1');
      expect(updated.language, 'javascript');
      expect(updated.code, 'console.log("hello");');
    });

    test('Note serialization includes codeBlocks', () {
      final note = Note(
        id: 'note-1',
        title: 'Tech Specs',
        body: 'Sample description',
        folderId: NotesConstants.defaultNotesFolderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        codeBlocks: [
          NoteCodeBlock(
            id: 'block-1',
            language: 'sql',
            code: 'SELECT * FROM users;',
          ),
        ],
      );

      final json = note.toJson();
      expect(json['codeBlocks'], isA<List>());
      expect((json['codeBlocks'] as List).length, 1);

      final reconstructed = Note.fromJson(json);
      expect(reconstructed.codeBlocks.length, 1);
      expect(reconstructed.codeBlocks.first.language, 'sql');
      expect(reconstructed.codeBlocks.first.code, 'SELECT * FROM users;');
    });
  });

  group('NotesProvider Code Block Operations Tests', () {
    test('addCodeBlock adds a code block to selected note', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(folderId: NotesConstants.defaultNotesFolderId);
      expect(provider.selectedNote!.codeBlocks, isEmpty);

      await provider.addCodeBlock(note.id, language: 'python', code: 'print(42)');
      expect(provider.selectedNote!.codeBlocks.length, 1);
      final block = provider.selectedNote!.codeBlocks.first;
      expect(block.language, 'python');
      expect(block.code, 'print(42)');
    });

    test('updateCodeBlockText modifies code content', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(folderId: NotesConstants.defaultNotesFolderId);
      await provider.addCodeBlock(note.id, language: 'dart', code: 'int x = 1;');
      final blockId = provider.selectedNote!.codeBlocks.first.id;

      await provider.updateCodeBlockText(note.id, blockId, 'int x = 42;\nprint(x);');
      expect(provider.selectedNote!.codeBlocks.first.code, 'int x = 42;\nprint(x);');
    });

    test('updateCodeBlockLanguage modifies language ID', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(folderId: NotesConstants.defaultNotesFolderId);
      await provider.addCodeBlock(note.id, language: 'dart', code: '// code');
      final blockId = provider.selectedNote!.codeBlocks.first.id;

      await provider.updateCodeBlockLanguage(note.id, blockId, 'javascript');
      expect(provider.selectedNote!.codeBlocks.first.language, 'javascript');
    });

    test('removeCodeBlock deletes the code block from note', () async {
      final provider = NotesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final note = await provider.createNote(folderId: NotesConstants.defaultNotesFolderId);
      await provider.addCodeBlock(note.id, language: 'bash', code: 'ls -la');
      expect(provider.selectedNote!.codeBlocks.length, 1);
      final blockId = provider.selectedNote!.codeBlocks.first.id;

      await provider.removeCodeBlock(note.id, blockId);
      expect(provider.selectedNote!.codeBlocks, isEmpty);
    });
  });

  group('Markdown Code Trigger Tests', () {
    test('parseMarkdownToDocument formats inline code properly', () {
      const markdown = 'Here is some `const x = 10;` inline code.';
      final doc = MarkdownConverter.parseMarkdownToDocument(markdown);

      // Verify delta contains inline code attribute
      final delta = doc.toDelta();
      bool foundInlineCode = false;
      for (final op in delta.operations) {
        if (op.attributes != null && op.attributes!['code'] == true) {
          foundInlineCode = true;
          expect(op.data, 'const x = 10;');
        }
      }
      expect(foundInlineCode, isTrue);
    });

    test('handleInteractiveMarkdown converts backtick snippets to inlineCode', () {
      final doc = Document();
      doc.insert(0, 'Use `print()` ');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 14),
      );

      final converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, isTrue);

      final text = controller.document.toPlainText();
      expect(text.contains('`'), isFalse);
      expect(text.contains('print()'), isTrue);
    });

    test('handleInteractiveMarkdown converts ``` to codeBlock', () {
      final doc = Document();
      doc.insert(0, '```');
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 3),
      );

      final converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, isTrue);
      expect(controller.getSelectionStyle().containsKey(Attribute.codeBlock.key), isTrue);
    });
  });

  group('CodeBlockWidget UI Tests', () {
    testWidgets('renders code block with language, line numbers and copy button', (tester) async {
      final block = NoteCodeBlock(
        id: 'b-1',
        language: 'python',
        code: 'def compute():\n    return 100',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CodeBlockWidget(
                codeBlock: block,
                onCodeChanged: (_) {},
                onLanguageChanged: (_) {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Language Badge
      expect(find.text('Python / Django'), findsOneWidget);

      // Verify Copy Button
      expect(find.text('Copy'), findsOneWidget);

      // Verify Code Content
      expect(find.text('def compute():\n    return 100'), findsOneWidget);

      // Verify Line Numbers Gutter
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('copy button triggers copy state', (tester) async {
      final block = NoteCodeBlock(
        id: 'b-1',
        language: 'dart',
        code: 'print("Hello macOS");',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CodeBlockWidget(
                codeBlock: block,
                onCodeChanged: (_) {},
                onLanguageChanged: (_) {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      );

      // Tap Copy button
      await tester.tap(find.text('Copy'));
      await tester.pump();

      // Should show 'Copied!'
      expect(find.text('Copied!'), findsOneWidget);

      // Advance past 2-second timer so timer completes cleanly
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('delete button triggers onDelete callback', (tester) async {
      bool deleted = false;
      final block = NoteCodeBlock(
        id: 'b-1',
        language: 'plain',
        code: 'some snippet',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CodeBlockWidget(
                codeBlock: block,
                onCodeChanged: (_) {},
                onLanguageChanged: (_) {},
                onDelete: () => deleted = true,
              ),
            ),
          ),
        ),
      );

      // Find delete button
      final deleteIcon = find.byIcon(CupertinoIcons.trash);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pump();

      expect(deleted, isTrue);
    });
  });
}
