/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Pixel-accurate macOS unified toolbar featuring fluid icon button hover/press feedback, animated segmented controls, and search transitions.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:mac_notes_app/features/theme/presentation/theme_mode_switcher.dart';
import 'package:provider/provider.dart';

/// Pixel-accurate macOS unified toolbar matching Apple Notes.
class MacToolbar extends StatefulWidget {
  final VoidCallback onToggleChecklist;
  final VoidCallback onInsertTable;
  final VoidCallback onToggleFormatMenu;
  final VoidCallback onInsertCodeBlock;
  final VoidCallback onAttachMedia;
  final VoidCallback onToggleLock;

  const MacToolbar({
    super.key,
    required this.onToggleChecklist,
    required this.onInsertTable,
    required this.onToggleFormatMenu,
    required this.onInsertCodeBlock,
    required this.onAttachMedia,
    required this.onToggleLock,
  });

  @override
  State<MacToolbar> createState() => _MacToolbarState();
}

class _MacToolbarState extends State<MacToolbar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final isDark = NotesTheme.isDark(context);

    return AnimatedContainer(
      duration: NotesConstants.themeAnimationDuration,
      curve: NotesConstants.defaultAnimationCurve,
      height: NotesConstants.toolbarHeight,
      padding: const EdgeInsets.only(
        left: NotesConstants.trafficLightInsetLeft,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: NotesTheme.toolbarBackground(context),
        border: Border(
          bottom: BorderSide(
            color: NotesTheme.divider(context),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Sidebar Toggle Button
          _ToolbarIconButton(
            icon: CupertinoIcons.sidebar_left,
            tooltip: 'Hide or show sidebar',
            isActive: !folderProvider.isSidebarCollapsed,
            onPressed: () => folderProvider.toggleSidebar(),
          ),

          const SizedBox(width: 8),

          // 2. View Mode Switcher (List vs Gallery)
          AnimatedContainer(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            height: 28,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF323236) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(6.0),
            ),
            padding: const EdgeInsets.all(2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentedIconButton(
                  icon: CupertinoIcons.list_bullet,
                  tooltip: 'View notes as a list',
                  isSelected: notesProvider.viewMode == NotesViewMode.list,
                  onPressed: () => notesProvider.setViewMode(NotesViewMode.list),
                ),
                _SegmentedIconButton(
                  icon: CupertinoIcons.square_grid_2x2,
                  tooltip: 'View notes as a gallery',
                  isSelected: notesProvider.viewMode == NotesViewMode.gallery,
                  onPressed: () => notesProvider.setViewMode(NotesViewMode.gallery),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 3. Delete Selected Note Button
          _ToolbarIconButton(
            icon: CupertinoIcons.trash,
            tooltip: 'Delete note',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: () {
              if (notesProvider.selectedNoteId != null) {
                notesProvider.deleteNote(notesProvider.selectedNoteId!);
              }
            },
          ),

          const SizedBox(width: 8),

          // 4. Compose / New Note Button
          _ToolbarIconButton(
            icon: CupertinoIcons.square_pencil,
            tooltip: 'Create a new note (Cmd+N)',
            color: NotesTheme.accentGold,
            onPressed: () {
              notesProvider.createNote(folderId: folderProvider.selectedFolderId);
            },
          ),

          const Spacer(),

          // 5. Checklist button
          _ToolbarIconButton(
            icon: CupertinoIcons.checkmark_circle,
            tooltip: 'Add checklist',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onToggleChecklist,
          ),

          const SizedBox(width: 4),

          // 6. Table button
          _ToolbarIconButton(
            icon: CupertinoIcons.table,
            tooltip: 'Add table',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onInsertTable,
          ),

          const SizedBox(width: 4),

          // 7. Typography / Format Menu button (Aa)
          _ToolbarIconButton(
            icon: CupertinoIcons.textformat,
            tooltip: 'Format text styles',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onToggleFormatMenu,
          ),

          const SizedBox(width: 4),

          // 8. Code Block button (</>)
          _ToolbarIconButton(
            icon: CupertinoIcons.chevron_left_slash_chevron_right,
            tooltip: 'Insert code block (Cmd+Shift+C)',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onInsertCodeBlock,
          ),

          const SizedBox(width: 4),

          // 9. Attachment button
          _ToolbarIconButton(
            icon: CupertinoIcons.paperclip,
            tooltip: 'Attach file or photo',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onAttachMedia,
          ),

          const SizedBox(width: 4),

          // 10. Lock Note button
          _ToolbarIconButton(
            icon: notesProvider.selectedNote?.isLocked == true
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock,
            tooltip: notesProvider.selectedNote?.isLocked == true ? 'Unlock note' : 'Lock note',
            enabled: notesProvider.selectedNoteId != null,
            onPressed: widget.onToggleLock,
          ),

          const SizedBox(width: 14),

          // 11. Search Input Pill
          SizedBox(
            width: 180,
            height: 28,
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Search all notes',
              placeholderStyle: TextStyle(
                color: NotesTheme.textTertiary(context),
                fontSize: 12.5,
              ),
              style: TextStyle(
                color: NotesTheme.textPrimary(context),
                fontSize: 12.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  CupertinoIcons.search,
                  size: 14.0,
                  color: NotesTheme.textTertiary(context),
                ),
              ),
              suffix: AnimatedSwitcher(
                duration: NotesConstants.microAnimationDuration,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                        key: const ValueKey('clear_search_btn'),
                        padding: const EdgeInsets.only(right: 6.0),
                        minimumSize: Size.zero,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          notesProvider.setSearchQuery('');
                        },
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 14.0,
                          color: NotesTheme.textTertiary(context),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_search_btn')),
              ),
              decoration: BoxDecoration(
                color: NotesTheme.searchBackground(context),
                borderRadius: BorderRadius.circular(6.0),
              ),
              onChanged: (val) {
                setState(() {});
                notesProvider.setSearchQuery(val);
              },
            ),
          ),

          const SizedBox(width: 10),

          // 12. Theme Mode Switcher (System / Light / Dark)
          const ThemeModeSwitcher(),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isActive;
  final Color? color;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.enabled = true,
    this.isActive = false,
    this.color,
  });

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final effectiveColor = widget.enabled
        ? (widget.color ??
            (widget.isActive ? NotesTheme.accentGold : NotesTheme.textPrimary(context)))
        : NotesTheme.textTertiary(context);

    final Color hoverBg = (widget.enabled && _isHovered)
        ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))
        : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedScale(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            scale: (widget.enabled && _isPressed) ? 0.92 : 1.0,
            child: AnimatedContainer(
              duration: NotesConstants.microAnimationDuration,
              curve: NotesConstants.defaultAnimationCurve,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hoverBg,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: NotesConstants.microAnimationDuration,
                  child: Icon(
                    widget.icon,
                    key: ValueKey<IconData>(widget.icon),
                    size: 17.5,
                    color: effectiveColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _SegmentedIconButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_SegmentedIconButton> createState() => _SegmentedIconButtonState();
}

class _SegmentedIconButtonState extends State<_SegmentedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    Color bg = Colors.transparent;
    if (widget.isSelected) {
      bg = isDark ? const Color(0xFF4A4A4E) : Colors.white;
    } else if (_isHovered) {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04);
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: 13.5,
              color: widget.isSelected
                  ? NotesTheme.textPrimary(context)
                  : NotesTheme.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
