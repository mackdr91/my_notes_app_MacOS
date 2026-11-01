import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/markdown_converter.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/format_menu_bar.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/attachment_widget.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/checklist_item_widget.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final note = notesProvider.selectedNote;

    if (note == null) {
      return Container(
        color: NotesTheme.editorBackground(context),
        child: Center(
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
        ),
      );
    }

    if (note.isLocked) {
      return _LockedNoteView(note: note);
    }

    if (_quillController == null) {
      return Container(
        color: NotesTheme.editorBackground(context),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

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
    );

    return Container(
      color: NotesTheme.editorBackground(context),
      child: Stack(
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

                      // Interactive Checklists Section
                      if (note.checklists.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...note.checklists.map((item) {
                          return ChecklistItemWidget(
                            item: item,
                            onToggle: (_) => notesProvider.toggleChecklist(note.id, item.id),
                            onTextChanged: (newText) =>
                                notesProvider.updateChecklistText(note.id, item.id, newText),
                            onDelete: () => notesProvider.removeChecklist(note.id, item.id),
                          );
                        }),
                      ],

                      // Embedded Data Tables Section
                      if (note.tables.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...note.tables.map((table) {
                          return NoteTableWidget(
                            table: table,
                            onCellChanged: (row, col, val) =>
                                notesProvider.updateTableCell(note.id, table.id, row, col, val),
                            onAddRow: () => notesProvider.addTableRow(note.id, table.id),
                            onAddColumn: () => notesProvider.addTableColumn(note.id, table.id),
                            onDeleteTable: () => notesProvider.removeTable(note.id, table.id),
                            onDeleteRow: (rowIndex) =>
                                notesProvider.deleteTableRow(note.id, table.id, rowIndex),
                            onDeleteColumn: (colIndex) =>
                                notesProvider.deleteTableColumn(note.id, table.id, colIndex),
                            onInsertRow: (atIndex) =>
                                notesProvider.insertTableRow(note.id, table.id, atIndex),
                            onInsertColumn: (atIndex) =>
                                notesProvider.insertTableColumn(note.id, table.id, atIndex),
                          );
                        }),
                      ],

                      // Attachments Section
                      if (note.attachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...note.attachments.map((attachment) {
                          return AttachmentWidget(
                            attachment: attachment,
                            onDelete: () => notesProvider.removeAttachment(note.id, attachment.id),
                          );
                        }),
                      ],

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Bottom Status Bar (Word & Character Count)
              Container(
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
                      child: Text(
                        '$_wordCount words, $_charCount characters',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: NotesTheme.textTertiary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Format Menu ('Aa' popover)
          if (widget.showFormatMenu)
            Positioned(
              top: 10,
              right: 60,
              child: FormatMenuBar(
                onSelectFormat: (format) {
                  _applyFormat(format);
                  widget.onCloseFormatMenu();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedNoteView extends StatefulWidget {
  final Note note;

  const _LockedNoteView({required this.note});

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
    return Container(
      color: NotesTheme.editorBackground(context),
      child: Center(
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 11.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                onPressed: _unlock,
                child: const Text('Unlock', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
