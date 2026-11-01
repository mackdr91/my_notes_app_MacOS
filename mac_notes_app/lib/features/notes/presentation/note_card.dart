import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Note card item in the middle list view matching Apple Notes.
class NoteCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final notesProvider = context.read<NotesProvider>();
    final folderProvider = context.read<FolderProvider>();

    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = isDark ? const Color(0xFF4A3E1E) : const Color(0xFFFDECB2);
    } else if (_isHovered) {
      backgroundColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    }

    final relativeDate = NotesUtils.formatListDate(widget.note.updatedAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition, notesProvider, folderProvider);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title and Pin/Lock icons
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.note.title.isEmpty ? 'New Note' : widget.note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: NotesTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  if (widget.note.isPinned) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.pin_fill,
                      size: 12.0,
                      color: NotesTheme.accentGold,
                    ),
                  ],
                  if (widget.note.isLocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.lock_fill,
                      size: 11.5,
                      color: NotesTheme.textSecondary(context),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 3.0),

              // Row 2: Relative timestamp + Snippet excerpt
              Row(
                children: [
                  Text(
                    relativeDate,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: widget.isSelected
                          ? NotesTheme.textPrimary(context)
                          : NotesTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      widget.note.snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: NotesTheme.textTertiary(context),
                      ),
                    ),
                  ),
                ],
              ),

              // Row 3: Folder or tag chips (if any)
              if (widget.note.tags.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Wrap(
                  spacing: 4.0,
                  children: widget.note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: NotesTheme.textSecondary(context),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    NotesProvider notesProvider,
    FolderProvider folderProvider,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.note.title.isEmpty ? 'Note Options' : widget.note.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              notesProvider.togglePin(widget.note.id);
            },
            child: Text(widget.note.isPinned ? 'Unpin Note' : 'Pin Note'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              notesProvider.duplicateNote(widget.note.id);
            },
            child: const Text('Duplicate Note'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              notesProvider.deleteNote(widget.note.id);
            },
            child: const Text('Delete Note'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
