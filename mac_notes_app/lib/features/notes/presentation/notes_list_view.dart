import 'package:flutter/cupertino.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/note_card.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Middle Column of Apple Notes: Grouped chronological note list.
class NotesListView extends StatelessWidget {
  const NotesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();

    if (notesProvider.isLoading) {
      return Container(
        color: NotesTheme.listBackground(context),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final notes = notesProvider.getFilteredNotes(folderProvider.selectedFolderId);

    if (notes.isEmpty) {
      return Container(
        color: NotesTheme.listBackground(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 42,
                color: NotesTheme.textTertiary(context),
              ),
              const SizedBox(height: 10),
              Text(
                notesProvider.searchQuery.isNotEmpty
                    ? 'No Results Found'
                    : 'No Notes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: NotesTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notesProvider.searchQuery.isNotEmpty
                    ? 'Try a different search query'
                    : 'Create a note with Cmd+N',
                style: TextStyle(
                  fontSize: 12,
                  color: NotesTheme.textTertiary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

    final Map<String, List<Note>> groupedNotes = {};
    for (final note in unpinnedNotes) {
      final group = NotesUtils.getDateGroupName(note.updatedAt);
      groupedNotes.putIfAbsent(group, () => []).add(note);
    }

    return Container(
      color: NotesTheme.listBackground(context),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          if (pinnedNotes.isNotEmpty) ...[
            const _GroupHeader(title: 'PINNED'),
            ...pinnedNotes.map((note) => NoteCard(
                  note: note,
                  isSelected: notesProvider.selectedNoteId == note.id,
                  onTap: () => notesProvider.selectNote(note.id),
                )),
            const SizedBox(height: 8),
          ],
          ...groupedNotes.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupHeader(title: entry.key.toUpperCase()),
                ...entry.value.map((note) => NoteCard(
                      note: note,
                      isSelected: notesProvider.selectedNoteId == note.id,
                      onTap: () => notesProvider.selectNote(note.id),
                    )),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: NotesTheme.textTertiary(context),
        ),
      ),
    );
  }
}
