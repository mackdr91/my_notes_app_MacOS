import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lusid/core/utils/markdown_converter.dart';

void main() {
  group('MarkdownConverter Tests', () {
    test('converts interactive block triggers (#, ##, ###, -, 1., >, checklist)', () {
      // 1. H1 trigger
      var controller = QuillController.basic();
      controller.document.insert(0, '# ');
      controller.updateSelection(const TextSelection.collapsed(offset: 2), ChangeSource.local);
      var converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('header: 1'));

      // 2. H2 trigger
      controller = QuillController.basic();
      controller.document.insert(0, '## ');
      controller.updateSelection(const TextSelection.collapsed(offset: 3), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('header: 2'));

      // 3. H3 trigger
      controller = QuillController.basic();
      controller.document.insert(0, '### ');
      controller.updateSelection(const TextSelection.collapsed(offset: 4), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('header: 3'));

      // 4. Bullet list trigger
      controller = QuillController.basic();
      controller.document.insert(0, '- ');
      controller.updateSelection(const TextSelection.collapsed(offset: 2), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('list: bullet'));

      // 5. Numbered list trigger
      controller = QuillController.basic();
      controller.document.insert(0, '1. ');
      controller.updateSelection(const TextSelection.collapsed(offset: 3), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('list: ordered'));

      // 6. Blockquote trigger
      controller = QuillController.basic();
      controller.document.insert(0, '> ');
      controller.updateSelection(const TextSelection.collapsed(offset: 2), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('blockquote: true'));

      // 7. Checklist trigger
      controller = QuillController.basic();
      controller.document.insert(0, '[] ');
      controller.updateSelection(const TextSelection.collapsed(offset: 3), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toDelta().toString(), contains('list: unchecked'));
    });

    test('converts interactive inline markdown formatting (**bold**, *italic*, `code`, ~~strike~~)', () {
      // 1. Bold: **bold text**
      var controller = QuillController.basic();
      controller.document.insert(0, 'Some **important** message');
      // Cursor right after the closing asterisks
      controller.updateSelection(const TextSelection.collapsed(offset: 18), ChangeSource.local);
      var converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toPlainText(), isNot(contains('**important**')));
      expect(controller.document.toPlainText(), contains('Some important message'));
      expect(controller.document.toDelta().toString(), contains('bold: true'));

      // 2. Italic: *italic text*
      controller = QuillController.basic();
      controller.document.insert(0, 'Here is *italic* note');
      controller.updateSelection(const TextSelection.collapsed(offset: 16), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toPlainText(), isNot(contains('*italic*')));
      expect(controller.document.toPlainText(), contains('Here is italic note'));
      expect(controller.document.toDelta().toString(), contains('italic: true'));

      // 3. Inline Code: `my_code`
      controller = QuillController.basic();
      controller.document.insert(0, 'Call `print()` now');
      controller.updateSelection(const TextSelection.collapsed(offset: 14), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toPlainText(), isNot(contains('`print()`')));
      expect(controller.document.toPlainText(), contains('Call print() now'));
      expect(controller.document.toDelta().toString(), contains('code: true'));

      // 4. Strikethrough: ~~struck~~
      controller = QuillController.basic();
      controller.document.insert(0, 'Status is ~~done~~');
      controller.updateSelection(const TextSelection.collapsed(offset: 18), ChangeSource.local);
      converted = MarkdownConverter.handleInteractiveMarkdown(controller);
      expect(converted, true);
      expect(controller.document.toPlainText(), isNot(contains('~~done~~')));
      expect(controller.document.toPlainText(), contains('Status is done'));
      expect(controller.document.toDelta().toString(), contains('strike: true'));
    });

    test('parseMarkdownToDocument converts multi-line markdown to rich text without markdown syntax', () {
      const markdown = '# Project Overview\n'
          'This is **very important** and *urgent*.\n'
          '## Sub deliverables\n'
          '- Task 1\n'
          '- [ ] Pending item\n'
          '- [x] Completed item\n'
          '> Apple Notes Quote\n'
          'Run `flutter run` for development';

      final doc = MarkdownConverter.parseMarkdownToDocument(markdown);
      final plain = doc.toPlainText();

      // Ensure markdown syntax is stripped from text
      expect(plain, isNot(contains('# Project Overview')));
      expect(plain, contains('Project Overview'));
      expect(plain, isNot(contains('**very important**')));
      expect(plain, contains('very important'));
      expect(plain, isNot(contains('`flutter run`')));
      expect(plain, contains('flutter run'));
      expect(plain, contains('Pending item'));
      expect(plain, contains('Completed item'));

      // Ensure formatting attributes are applied
      final deltaStr = doc.toDelta().toString();
      expect(deltaStr, contains('header: 1'));
      expect(deltaStr, contains('header: 2'));
      expect(deltaStr, contains('bold: true'));
      expect(deltaStr, contains('italic: true'));
      expect(deltaStr, contains('list: bullet'));
      expect(deltaStr, contains('list: unchecked'));
      expect(deltaStr, contains('list: checked'));
      expect(deltaStr, contains('blockquote: true'));
      expect(deltaStr, contains('code: true'));
    });
  });
}
