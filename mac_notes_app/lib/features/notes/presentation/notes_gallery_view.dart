/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Gallery/Grid view mode for Apple Notes on macOS with fluid card hover lift, selection border, and folder switch transitions.
 */

import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
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
    final selectedFolderId = folderProvider.selectedFolderId;
    final activeTag = notesProvider.activeTag;
    final notes = notesProvider.getFilteredNotes(selectedFolderId);

    Widget content;

    if (notes.isEmpty) {
      content = Center(
        key: ValueKey('gallery_empty_${selectedFolderId}_$activeTag'),
        child: Text(
          'No Notes',
          style: TextStyle(
            fontSize: 15,
            color: NotesTheme.textSecondary(context),
          ),
        ),
      );
    } else {
      content = Padding(
        key: ValueKey('gallery_grid_${selectedFolderId}_$activeTag'),
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
              key: ValueKey('gallery_card_${note.id}'),
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

class _GalleryCard extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalleryCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    final double cardScale = _isPressed
        ? 0.975
        : (_isHovered ? 1.015 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: NotesConstants.microAnimationDuration,
          curve: NotesConstants.defaultAnimationCurve,
          scale: cardScale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: NotesConstants.microAnimationDuration,
                  curve: NotesConstants.defaultAnimationCurve,
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
                        color: Colors.black.withValues(
                          alpha: _isHovered
                              ? (isDark ? 0.45 : 0.12)
                              : (isDark ? 0.3 : 0.06),
                        ),
                        blurRadius: _isHovered ? 8 : 4,
                        offset: Offset(0, _isHovered ? 4 : 2),
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
              AnimatedDefaultTextStyle(
                duration: NotesConstants.microAnimationDuration,
                curve: NotesConstants.defaultAnimationCurve,
                style: TextStyle(
                  fontFamily: '.AppleSystemUIFont',
                  fontSize: 11.5,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: NotesTheme.textPrimary(context),
                ),
                child: Text(
                  widget.note.title.isEmpty ? 'New Note' : widget.note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
      ),
    );
  }
}
