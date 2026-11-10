/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Right-hand column WYSIWYG rich note editor featuring fluid note-switching transitions, animated format popover, and smooth embedded block animations.
 */

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/markdown_converter.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/format_menu_bar.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/attachment_widget.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/checklist_item_widget.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/code_block_widget.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/note_table_widget.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Right-hand Column of Apple Notes: Pixel-accurate WYSIWYG rich note editor.
class EditorView extends StatefulWidget {
  final bool showFormatMenu;
  final VoidCallback onCloseFormatMenu;

  const EditorView({
    super.key,
    this.showFormatMenu = false,
    required this.onCloseFormatMenu,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  QuillController? _quillController;
  final FocusNode _focusNode = FocusNode();
  String? _currentNoteId;
  int _wordCount = 0;
  int _charCount = 0;
  bool _isFormatting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final note = context.watch<NotesProvider>().selectedNote;
    if (note != null && note.id != _currentNoteId) {
      _currentNoteId = note.id;
      _initController(note);
    }
  }

  void _initController(Note note) {
    _quillController?.removeListener(_onDocumentChanged);
    _quillController?.dispose();

    Document doc;
    if (note.richTextJson != null && note.richTextJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(note.richTextJson!);
        doc = Document.fromJson(decoded as List<dynamic>);
      } catch (_) {
        doc = _createDocFromPlainContent(note);
      }
    } else {
      doc = _createDocFromPlainContent(note);
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _updateWordCharCounts();

    _quillController!.addListener(_onDocumentChanged);
  }

  Document _createDocFromPlainContent(Note note) {
    final fullText = note.fullContent;
    if (fullText.isEmpty) {
      final doc = Document();
      doc.insert(0, '\n');
      return doc;
    }
    return MarkdownConverter.parseMarkdownToDocument(fullText);
  }

  void _onDocumentChanged() {
    if (_quillController == null || _currentNoteId == null || _isFormatting) return;

    _isFormatting = true;
    try {
      MarkdownConverter.handleInteractiveMarkdown(_quillController!);
    } catch (_) {
      // Ignore conversion edge cases
    } finally {
      _isFormatting = false;
    }

    final plain = _quillController!.document.toPlainText().trim();
    final deltaJson = jsonEncode(_quillController!.document.toDelta().toJson());

    _updateWordCharCounts();

    context.read<NotesProvider>().updateNoteRichText(
          _currentNoteId!,
          richTextJson: deltaJson,
          plainText: plain,
        );
  }

  void _updateWordCharCounts() {
    if (_quillController == null) return;
    final text = _quillController!.document.toPlainText().trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : RegExp(r'\S+').allMatches(text).length;
      _charCount = text.length;
    });
  }

  @override
  void dispose() {
    _quillController?.removeListener(_onDocumentChanged);
    _quillController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyFormat(NoteTextFormat format) {
    if (_quillController == null) return;

    switch (format) {
      case NoteTextFormat.title:
        _quillController!.formatSelection(Attribute.h1);
        break;
      case NoteTextFormat.heading:
        _quillController!.formatSelection(Attribute.h2);
        break;
      case NoteTextFormat.subheading:
        _quillController!.formatSelection(Attribute.h3);
        break;
      case NoteTextFormat.body:
        _quillController!.formatSelection(Attribute.header);
        break;
      case NoteTextFormat.monospaced:
        _quillController!.formatSelection(Attribute.codeBlock);
        break;
      case NoteTextFormat.bulletList:
        _quillController!.formatSelection(Attribute.ul);
        break;
      case NoteTextFormat.numberedList:
        _quillController!.formatSelection(Attribute.ol);
        break;
      case NoteTextFormat.bold:
        _quillController!.formatSelection(Attribute.bold);
        break;
      case NoteTextFormat.italic:
        _quillController!.formatSelection(Attribute.italic);
        break;
      case NoteTextFormat.underline:
        _quillController!.formatSelection(Attribute.underline);
        break;
      case NoteTextFormat.strikethrough:
        _quillController!.formatSelection(Attribute.strikeThrough);
        break;
      case NoteTextFormat.code:
        _quillController!.formatSelection(Attribute.inlineCode);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final note = notesProvider.selectedNote;

    Widget bodyContent;

    if (note == null) {
      bodyContent = Center(
        key: const ValueKey('editor_empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.square_pencil,
              size: 48,
              color: NotesTheme.textTertiary(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No Note Selected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NotesTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    } else if (note.isLocked) {
      bodyContent = _LockedNoteView(
        key: ValueKey('editor_locked_${note.id}'),
        note: note,
      );
    } else if (_quillController == null) {
      bodyContent = const Center(
        key: ValueKey('editor_loading'),
        child: CupertinoActivityIndicator(),
      );
    } else {
      final appleCustomStyles = DefaultStyles(
        h1: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: NotesTheme.textPrimary(context),
            height: 1.25,
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(4, 8),
          const VerticalSpacing(0, 0),
          null,
        ),
        h2: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontSize: 19.0,
            fontWeight: FontWeight.w600,
            color: NotesTheme.textPrimary(context),
            height: 1.3,
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(4, 6),
          const VerticalSpacing(0, 0),
          null,
        ),
        h3: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: NotesTheme.textPrimary(context),
            height: 1.35,
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(2, 4),
          const VerticalSpacing(0, 0),
          null,
        ),
        paragraph: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontSize: 14.5,
            fontWeight: FontWeight.normal,
            color: NotesTheme.textPrimary(context),
            height: 1.45,
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(2, 2),
          const VerticalSpacing(0, 0),
          null,
        ),
        code: DefaultTextBlockStyle(
          TextStyle(
            fontFamily: 'SF Mono',
            fontSize: 13.0,
            color: NotesTheme.textPrimary(context),
          ),
          const HorizontalSpacing(0, 0),
          const VerticalSpacing(4, 4),
          const VerticalSpacing(0, 0),
          BoxDecoration(
            color: NotesTheme.codeBackground(context),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        inlineCode: InlineCodeStyle(
          style: TextStyle(
            fontFamily: 'SF Mono',
            fontSize: 13.0,
            color: NotesTheme.textPrimary(context),
          ),
          backgroundColor: NotesTheme.codeBackground(context),
          radius: const Radius.circular(3.0),
        ),
      );

      bodyContent = Stack(
        key: ValueKey('editor_unlocked_${note.id}'),
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered Date Timestamp Header
                      Center(
                        child: Text(
                          NotesUtils.formatEditorHeaderDate(note.updatedAt),
                          style: NotesTheme.dateHeaderStyle(context),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      // WYSIWYG Rich Text Quill Editor
                      QuillEditor.basic(
                        controller: _quillController!,
                        focusNode: _focusNode,
                        config: QuillEditorConfig(
                          placeholder: 'Note text',
                          autoFocus: false,
                          customStyles: appleCustomStyles,
                          padding: EdgeInsets.zero,
                          showCursor: true,
                        ),
                      ),

                      // Interactive Checklists Section with animated size expansion
                      AnimatedSize(
                        duration: NotesConstants.contentAnimationDuration,
                        curve: NotesConstants.defaultAnimationCurve,
                        alignment: Alignment.topCenter,
                        child: note.checklists.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: note.checklists.map((item) {
                                    return ChecklistItemWidget(
                                      key: ValueKey('checklist_${item.id}'),
                                      item: item,
                                      onToggle: (_) =>
                                          notesProvider.toggleChecklist(note.id, item.id),
                                      onTextChanged: (newText) => notesProvider
                                          .updateChecklistText(note.id, item.id, newText),
                                      onDelete: () =>
                                          notesProvider.removeChecklist(note.id, item.id),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Embedded Data Tables Section with animated size expansion
                      AnimatedSize(
                        duration: NotesConstants.contentAnimationDuration,
                        curve: NotesConstants.defaultAnimationCurve,
                        alignment: Alignment.topCenter,
                        child: note.tables.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: note.tables.map((table) {
                                    return NoteTableWidget(
                                      key: ValueKey('table_${table.id}'),
                                      table: table,
                                      onCellChanged: (row, col, val) => notesProvider
                                          .updateTableCell(note.id, table.id, row, col, val),
                                      onAddRow: () =>
                                          notesProvider.addTableRow(note.id, table.id),
                                      onAddColumn: () =>
                                          notesProvider.addTableColumn(note.id, table.id),
                                      onDeleteTable: () =>
                                          notesProvider.removeTable(note.id, table.id),
                                      onDeleteRow: (rowIndex) => notesProvider.deleteTableRow(
                                          note.id, table.id, rowIndex),
                                      onDeleteColumn: (colIndex) => notesProvider
                                          .deleteTableColumn(note.id, table.id, colIndex),
                                      onInsertRow: (atIndex) => notesProvider.insertTableRow(
                                          note.id, table.id, atIndex),
                                      onInsertColumn: (atIndex) => notesProvider
                                          .insertTableColumn(note.id, table.id, atIndex),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Embedded Code Blocks Section with animated size expansion
                      AnimatedSize(
                        duration: NotesConstants.contentAnimationDuration,
                        curve: NotesConstants.defaultAnimationCurve,
                        alignment: Alignment.topCenter,
                        child: note.codeBlocks.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: note.codeBlocks.map((block) {
                                    return Padding(
                                      key: ValueKey('codeblock_${block.id}'),
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: CodeBlockWidget(
                                        codeBlock: block,
                                        onCodeChanged: (newCode) => notesProvider
                                            .updateCodeBlockText(note.id, block.id, newCode),
                                        onLanguageChanged: (newLang) => notesProvider
                                            .updateCodeBlockLanguage(
                                                note.id, block.id, newLang),
                                        onDelete: () => notesProvider.removeCodeBlock(
                                            note.id, block.id),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Attachments Section with animated size expansion
                      AnimatedSize(
                        duration: NotesConstants.contentAnimationDuration,
                        curve: NotesConstants.defaultAnimationCurve,
                        alignment: Alignment.topCenter,
                        child: note.attachments.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: note.attachments.map((attachment) {
                                    return AttachmentWidget(
                                      key: ValueKey('attachment_${attachment.id}'),
                                      attachment: attachment,
                                      onDelete: () => notesProvider.removeAttachment(
                                          note.id, attachment.id),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Bottom Status Bar (Word & Character Count)
              AnimatedContainer(
                duration: NotesConstants.themeAnimationDuration,
                curve: NotesConstants.defaultAnimationCurve,
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: NotesTheme.divider(context),
                      width: 0.6,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: NotesConstants.microAnimationDuration,
                        child: Text(
                          '$_wordCount words, $_charCount characters',
                          key: ValueKey<String>('${_wordCount}_$_charCount'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: NotesTheme.textTertiary(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Format Menu ('Aa' popover) with scale & fade animation
          Positioned(
            top: 10,
            right: 60,
            child: AnimatedSwitcher(
              duration: NotesConstants.microAnimationDuration,
              switchInCurve: NotesConstants.defaultAnimationCurve,
              switchOutCurve: NotesConstants.exitAnimationCurve,
              transitionBuilder: (child, animation) {
                final scaleAnimation = Tween<double>(
                  begin: 0.92,
                  end: 1.0,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    alignment: Alignment.topRight,
                    child: child,
                  ),
                );
              },
              child: widget.showFormatMenu
                  ? FormatMenuBar(
                      key: const ValueKey('format_menu_open'),
                      onSelectFormat: (format) {
                        _applyFormat(format);
                        widget.onCloseFormatMenu();
                      },
                    )
                  : const SizedBox.shrink(key: ValueKey('format_menu_closed')),
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: NotesConstants.themeAnimationDuration,
      curve: NotesConstants.defaultAnimationCurve,
      color: NotesTheme.editorBackground(context),
      child: AnimatedSwitcher(
        duration: NotesConstants.contentAnimationDuration,
        switchInCurve: NotesConstants.defaultAnimationCurve,
        switchOutCurve: NotesConstants.exitAnimationCurve,
        transitionBuilder: (child, animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.015),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
        child: bodyContent,
      ),
    );
  }
}

class _LockedNoteView extends StatefulWidget {
  final Note note;

  const _LockedNoteView({super.key, required this.note});

  @override
  State<_LockedNoteView> createState() => _LockedNoteViewState();
}

class _LockedNoteViewState extends State<_LockedNoteView> {
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _unlock() {
    final provider = context.read<NotesProvider>();
    if (provider.verifyPassword(widget.note.id, _passwordController.text)) {
      provider.setNoteLock(widget.note.id, isLocked: false);
    } else {
      setState(() => _errorMessage = 'Incorrect password. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NotesTheme.accentGold.withValues(alpha: 0.15),
              ),
              child: const Icon(
                CupertinoIcons.lock_fill,
                size: 26,
                color: NotesTheme.accentGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This Note is Locked',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NotesTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter password to view note contents',
              style: TextStyle(
                fontSize: 12.5,
                color: NotesTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _passwordController,
              obscureText: true,
              placeholder: 'Password',
              style: TextStyle(
                color: NotesTheme.textPrimary(context),
                fontSize: 13.0,
              ),
              onSubmitted: (_) => _unlock(),
            ),
            AnimatedSize(
              duration: NotesConstants.microAnimationDuration,
              curve: NotesConstants.defaultAnimationCurve,
              child: _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 11.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              onPressed: _unlock,
              child: const Text('Unlock', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
