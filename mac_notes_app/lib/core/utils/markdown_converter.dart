// Author: Domonick Mack
// Date: 2026-11-10
// Description: Real-time Markdown to FlutterQuill Delta rich text converter.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Converts markdown syntax to formatted rich text in real-time while typing or from multi-line text.
class MarkdownConverter {
  /// Converts interactive typing markdown shortcuts into formatted rich text.
  /// Returns true if a transformation was applied.
  static bool handleInteractiveMarkdown(QuillController controller) {
    final selection = controller.selection;
    if (!selection.isCollapsed || selection.baseOffset <= 0) return false;

    final offset = selection.baseOffset;
    final plainText = controller.document.toPlainText();
    if (offset > plainText.length) return false;

    // Find the start of the current line
    final lineStart = plainText.lastIndexOf('\n', offset - 1) + 1;
    final lineUpToCursor = plainText.substring(lineStart, offset);

    // 1. Line Block Starters (triggered when user types prefix + space)
    if (lineUpToCursor == '# ') {
      controller.replaceText(lineStart, 2, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.h1);
      return true;
    } else if (lineUpToCursor == '## ') {
      controller.replaceText(lineStart, 3, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.h2);
      return true;
    } else if (lineUpToCursor == '### ') {
      controller.replaceText(lineStart, 4, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.h3);
      return true;
    } else if (lineUpToCursor == '- [ ] ' ||
        lineUpToCursor == '[] ' ||
        lineUpToCursor == '[ ] ') {
      controller.replaceText(lineStart, lineUpToCursor.length, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.unchecked);
      return true;
    } else if (lineUpToCursor == '- [x] ' || lineUpToCursor == '[x] ') {
      controller.replaceText(lineStart, lineUpToCursor.length, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.checked);
      return true;
    } else if (lineUpToCursor == '- ' || lineUpToCursor == '* ') {
      controller.replaceText(lineStart, 2, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.ul);
      return true;
    } else if (RegExp(r'^\d+\.\s$').hasMatch(lineUpToCursor)) {
      controller.replaceText(lineStart, lineUpToCursor.length, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.ol);
      return true;
    } else if (lineUpToCursor == '> ') {
      controller.replaceText(lineStart, 2, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.blockQuote);
      return true;
    } else if (lineUpToCursor.trim() == '```') {
      controller.replaceText(lineStart, lineUpToCursor.length, '', null);
      controller.updateSelection(
        TextSelection.collapsed(offset: lineStart),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.codeBlock);
      return true;
    }

    // 2. Inline Markdown (triggered when closing delimiter is typed or followed by space)
    // Bold: **text** or __text__
    final boldAsteriskMatch = RegExp(r'\*\*([^*]+)\*\*(\s?)$')
        .firstMatch(lineUpToCursor);
    if (boldAsteriskMatch != null) {
      final inner = boldAsteriskMatch.group(1)!;
      final trailing = boldAsteriskMatch.group(2) ?? '';
      final start = lineStart + boldAsteriskMatch.start;
      final len = boldAsteriskMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.bold);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    final boldUnderscoreMatch = RegExp(r'__([^_]+)__(\s?)$')
        .firstMatch(lineUpToCursor);
    if (boldUnderscoreMatch != null) {
      final inner = boldUnderscoreMatch.group(1)!;
      final trailing = boldUnderscoreMatch.group(2) ?? '';
      final start = lineStart + boldUnderscoreMatch.start;
      final len = boldUnderscoreMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.bold);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    // Italic: *text* or _text_ (avoiding double asterisks or double underscores)
    final italicAsteriskMatch = RegExp(r'(?<!\*)\*([^*]+)\*(\s?)$')
        .firstMatch(lineUpToCursor);
    if (italicAsteriskMatch != null) {
      final inner = italicAsteriskMatch.group(1)!;
      final trailing = italicAsteriskMatch.group(2) ?? '';
      final start = lineStart + italicAsteriskMatch.start;
      final len = italicAsteriskMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.italic);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    final italicUnderscoreMatch = RegExp(r'(?<!_)_([^_]+)_(\s?)$')
        .firstMatch(lineUpToCursor);
    if (italicUnderscoreMatch != null) {
      final inner = italicUnderscoreMatch.group(1)!;
      final trailing = italicUnderscoreMatch.group(2) ?? '';
      final start = lineStart + italicUnderscoreMatch.start;
      final len = italicUnderscoreMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.italic);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    // Inline Code: `text`
    final codeMatch = RegExp(r'`([^`]+)`(\s?)$').firstMatch(lineUpToCursor);
    if (codeMatch != null) {
      final inner = codeMatch.group(1)!;
      final trailing = codeMatch.group(2) ?? '';
      final start = lineStart + codeMatch.start;
      final len = codeMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.inlineCode);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    // Strikethrough: ~~text~~
    final strikeMatch = RegExp(r'~~([^~]+)~~(\s?)$').firstMatch(lineUpToCursor);
    if (strikeMatch != null) {
      final inner = strikeMatch.group(1)!;
      final trailing = strikeMatch.group(2) ?? '';
      final start = lineStart + strikeMatch.start;
      final len = strikeMatch.group(0)!.length;

      controller.replaceText(start, len, '$inner$trailing', null);
      controller.formatText(start, inner.length, Attribute.strikeThrough);
      controller.updateSelection(
        TextSelection.collapsed(offset: start + inner.length + trailing.length),
        ChangeSource.local,
      );
      return true;
    }

    return false;
  }

  /// Converts a multi-line markdown or plain text string into a rich formatted Quill Document.
  static Document parseMarkdownToDocument(String markdown) {
    if (markdown.trim().isEmpty) {
      return Document()..insert(0, '\n');
    }

    final delta = Delta();
    final lines = markdown.split('\n');
    bool isFirstLine = true;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      Attribute? lineAttribute;

      if (line.startsWith('### ')) {
        line = line.substring(4);
        lineAttribute = Attribute.h3;
      } else if (line.startsWith('## ')) {
        line = line.substring(3);
        lineAttribute = Attribute.h2;
      } else if (line.startsWith('# ')) {
        line = line.substring(2);
        lineAttribute = Attribute.h1;
      } else if (line.startsWith('- [ ] ') ||
          line.startsWith('[] ') ||
          line.startsWith('[ ] ')) {
        line = line.replaceFirst(RegExp(r'^(-\s)?\[\s?\]\s*'), '');
        lineAttribute = Attribute.unchecked;
      } else if (line.startsWith('- [x] ') ||
          line.startsWith('- [X] ') ||
          line.startsWith('[x] ')) {
        line = line.replaceFirst(RegExp(r'^(-\s)?\[(x|X)\]\s*'), '');
        lineAttribute = Attribute.checked;
      } else if (line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('• ')) {
        line = line.substring(2);
        lineAttribute = Attribute.ul;
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        line = line.replaceFirst(RegExp(r'^\d+\.\s'), '');
        lineAttribute = Attribute.ol;
      } else if (line.startsWith('> ')) {
        line = line.substring(2);
        lineAttribute = Attribute.blockQuote;
      } else if (line.startsWith('```')) {
        line = line.replaceFirst(RegExp(r'^```\w*'), '');
        lineAttribute = Attribute.codeBlock;
      } else if (isFirstLine && line.trim().isNotEmpty) {
        // First line of note defaults to Title in Apple Notes
        lineAttribute = Attribute.h1;
      }

      isFirstLine = false;

      // Parse inline markdown tokens inside this line
      final spans = _parseInlineMarkdown(line);
      for (final span in spans) {
        if (span.text.isEmpty) continue;
        final Map<String, dynamic> attrs = {};
        if (span.isBold) {
          attrs[Attribute.bold.key] = Attribute.bold.value;
        }
        if (span.isItalic) {
          attrs[Attribute.italic.key] = Attribute.italic.value;
        }
        if (span.isCode) {
          attrs[Attribute.inlineCode.key] = Attribute.inlineCode.value;
        }
        if (span.isStrike) {
          attrs[Attribute.strikeThrough.key] = Attribute.strikeThrough.value;
        }

        delta.insert(span.text, attrs.isNotEmpty ? attrs : null);
      }

      // Add newline and line format
      final Map<String, dynamic>? lineAttrs = lineAttribute != null
          ? {lineAttribute.key: lineAttribute.value}
          : null;
      delta.insert('\n', lineAttrs);
    }

    return Document.fromDelta(delta);
  }

  static List<_InlineSpan> _parseInlineMarkdown(String text) {
    final List<_InlineSpan> result = [];
    final pattern = RegExp(
      r'(\*\*(.*?)\*\*)|(__([^_]+)__)|(\*(.*?)\*)|(_([^_]+)_)|(`(.*?)`)|(~~(.*?)~~)',
    );

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        result.add(_InlineSpan(text: text.substring(lastIndex, match.start)));
      }

      if (match.group(1) != null) {
        result.add(_InlineSpan(text: match.group(2)!, isBold: true));
      } else if (match.group(3) != null) {
        result.add(_InlineSpan(text: match.group(4)!, isBold: true));
      } else if (match.group(5) != null) {
        result.add(_InlineSpan(text: match.group(6)!, isItalic: true));
      } else if (match.group(7) != null) {
        result.add(_InlineSpan(text: match.group(8)!, isItalic: true));
      } else if (match.group(9) != null) {
        result.add(_InlineSpan(text: match.group(10)!, isCode: true));
      } else if (match.group(11) != null) {
        result.add(_InlineSpan(text: match.group(12)!, isStrike: true));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      result.add(_InlineSpan(text: text.substring(lastIndex)));
    }

    return result.isEmpty ? [_InlineSpan(text: text)] : result;
  }
}

class _InlineSpan {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isCode;
  final bool isStrike;

  _InlineSpan({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isCode = false,
    this.isStrike = false,
  });
}
