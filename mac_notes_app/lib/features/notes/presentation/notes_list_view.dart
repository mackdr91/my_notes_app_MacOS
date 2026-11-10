/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Middle column chronological note list featuring fluid folder/tag switching and state transitions.
 */

import 'package:flutter/cupertino.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
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
    final selectedFolderId = folderProvider.selectedFolderId;
    final activeTag = notesProvider.activeTag;
    final notes = notesProvider.getFilteredNotes(selectedFolderId);

    Widget content;

    if (notesProvider.isLoading) {
      content = const Center(
        key: ValueKey('list_loading'),
        child: CupertinoActivityIndicator(),
      );
    } else if (notes.isEmpty) {
      content = Center(
        key: ValueKey('list_empty_${notesProvider.searchQuery.isNotEmpty}_${selectedFolderId}_$activeTag'),
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
      );
    } else {
      final pinnedNotes = notes.where((n) => n.isPinned).toList();
      final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

      final Map<String, List<Note>> groupedNotes = {};
      for (final note in unpinnedNotes) {
        final group = NotesUtils.getDateGroupName(note.updatedAt);
        groupedNotes.putIfAbsent(group, () => []).add(note);
      }

      content = ListView(
        key: ValueKey('list_data_${selectedFolderId}_$activeTag'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          if (pinnedNotes.isNotEmpty) ...[
            const _GroupHeader(title: 'PINNED'),
            ...pinnedNotes.map((note) => NoteCard(
                  key: ValueKey('pinned_${note.id}'),
                  note: note,
                  isSelected: notesProvider.selectedNoteId == note.id,
                  onTap: () => notesProvider.selectNote(note.id),
                )),
            const SizedBox(height: 8),
          ],
          ...groupedNotes.entries.map((entry) {
            return Column(
              key: ValueKey('group_${entry.key}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupHeader(title: entry.key.toUpperCase()),
                ...entry.value.map((note) => NoteCard(
                      key: ValueKey('note_${note.id}'),
                      note: note,
                      isSelected: notesProvider.selectedNoteId == note.id,
                      onTap: () => notesProvider.selectNote(note.id),
                    )),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      );
    }

    return AnimatedContainer(
      duration: NotesConstants.themeAnimationDuration,
      curve: NotesConstants.defaultAnimationCurve,
      color: NotesTheme.listBackground(context),
      child: AnimatedSwitcher(
        duration: NotesConstants.contentAnimationDuration,
        switchInCurve: NotesConstants.defaultAnimationCurve,
        switchOutCurve: NotesConstants.exitAnimationCurve,
        transitionBuilder: (child, animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.02),
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
        child: content,
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
