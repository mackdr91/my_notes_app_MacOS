import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Gallery / Grid view mode for Apple Notes on macOS.
class NotesGalleryView extends StatelessWidget {
  const NotesGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.getFilteredNotes(folderProvider.selectedFolderId);

    if (notes.isEmpty) {
      return Container(
        color: NotesTheme.listBackground(context),
        child: Center(
          child: Text(
            'No Notes',
            style: TextStyle(
              fontSize: 15,
              color: NotesTheme.textSecondary(context),
            ),
          ),
        ),
      );
    }

    return Container(
      color: NotesTheme.listBackground(context),
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          final isSelected = notesProvider.selectedNoteId == note.id;
          return _GalleryCard(
            note: note,
            isSelected: isSelected,
            onTap: () {
              notesProvider.selectNote(note.id);
            },
          );
        },
      ),
    );
  }
}

class _GalleryCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalleryCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: widget.isSelected
                        ? NotesTheme.accentGold
                        : (_isHovered
                            ? (isDark ? const Color(0xFF4A4A4E) : const Color(0xFFC7C7CC))
                            : NotesTheme.divider(context)),
                    width: widget.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.note.title.isEmpty ? 'New Note' : widget.note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: NotesTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        widget.note.body,
                        maxLines: 6,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 10.0,
                          color: NotesTheme.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.note.title.isEmpty ? 'New Note' : widget.note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                color: NotesTheme.textPrimary(context),
              ),
            ),
            Text(
              NotesUtils.formatListDate(widget.note.updatedAt),
              style: TextStyle(
                fontSize: 10.0,
                color: NotesTheme.textTertiary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
