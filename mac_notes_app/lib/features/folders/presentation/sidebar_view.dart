/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Native macOS 3-column left sidebar for Apple Notes with fluid hover, selection, and tag list animations.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/widgets/about_notes_dialog.dart';
import 'package:mac_notes_app/features/folders/models/folder_model.dart';
import 'package:mac_notes_app/features/folders/presentation/add_folder_dialog.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Native macOS 3-column Left Sidebar for Apple Notes.
class SidebarView extends StatelessWidget {
  const SidebarView({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();

    if (folderProvider.isLoading) {
      return AnimatedContainer(
        duration: NotesConstants.themeAnimationDuration,
        curve: NotesConstants.defaultAnimationCurve,
        color: NotesTheme.sidebarBackground(context),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return AnimatedContainer(
      duration: NotesConstants.themeAnimationDuration,
      curve: NotesConstants.defaultAnimationCurve,
      color: NotesTheme.sidebarBackground(context),
      child: Column(
        children: [
          // Scrollable folder & tags tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              children: [
                // 1. Quick Notes
                if (folderProvider.quickNotesFolder != null) ...[
                  _SidebarItemTile(
                    key: const ValueKey(NotesConstants.quickNotesFolderId),
                    folder: folderProvider.quickNotesFolder!,
                    isSelected: folderProvider.selectedFolderId == NotesConstants.quickNotesFolderId,
                    count: notesProvider.countNotesInFolder(NotesConstants.quickNotesFolderId),
                    onTap: () {
                      notesProvider.setActiveTag(null);
                      folderProvider.selectFolder(NotesConstants.quickNotesFolderId);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 2. iCloud Section Header
                const _SectionHeader(title: 'iCloud'),
                const SizedBox(height: 4),

                // All iCloud
                _SidebarItemTile(
                  key: const ValueKey(NotesConstants.allNotesFolderId),
                  folder: Folder(
                    id: NotesConstants.allNotesFolderId,
                    name: 'All iCloud',
                    iconType: 'all_notes',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  isSelected: folderProvider.selectedFolderId == NotesConstants.allNotesFolderId,
                  count: notesProvider.countNotesInFolder(NotesConstants.allNotesFolderId),
                  onTap: () {
                    notesProvider.setActiveTag(null);
                    folderProvider.selectFolder(NotesConstants.allNotesFolderId);
                  },
                ),

                // Standard Notes Folder
                _SidebarItemTile(
                  key: const ValueKey(NotesConstants.defaultNotesFolderId),
                  folder: Folder(
                    id: NotesConstants.defaultNotesFolderId,
                    name: 'Notes',
                    iconType: 'folder',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  isSelected: folderProvider.selectedFolderId == NotesConstants.defaultNotesFolderId,
                  count: notesProvider.countNotesInFolder(NotesConstants.defaultNotesFolderId),
                  onTap: () {
                    notesProvider.setActiveTag(null);
                    folderProvider.selectFolder(NotesConstants.defaultNotesFolderId);
                  },
                ),

                // Custom user folders
                ...folderProvider.iCloudFolders
                    .where((f) => !f.isSystem)
                    .map((f) => _SidebarItemTile(
                          key: ValueKey(f.id),
                          folder: f,
                          isSelected: folderProvider.selectedFolderId == f.id,
                          count: notesProvider.countNotesInFolder(f.id),
                          onTap: () {
                            notesProvider.setActiveTag(null);
                            folderProvider.selectFolder(f.id);
                          },
                          onRename: () => _showRenameDialog(context, f),
                          onDelete: () => folderProvider.deleteFolder(f.id),
                        )),

                // Recently Deleted
                if (folderProvider.trashFolder != null) ...[
                  const SizedBox(height: 8),
                  _SidebarItemTile(
                    key: const ValueKey(NotesConstants.trashFolderId),
                    folder: folderProvider.trashFolder!,
                    isSelected: folderProvider.selectedFolderId == NotesConstants.trashFolderId,
                    count: notesProvider.countNotesInFolder(NotesConstants.trashFolderId),
                    onTap: () {
                      notesProvider.setActiveTag(null);
                      folderProvider.selectFolder(NotesConstants.trashFolderId);
                    },
                  ),
                ],

                const SizedBox(height: 18),

                // 3. TAGS Section with smooth size & fade animation
                AnimatedSize(
                  duration: NotesConstants.contentAnimationDuration,
                  curve: NotesConstants.defaultAnimationCurve,
                  alignment: Alignment.topCenter,
                  child: notesProvider.tagsWithCount.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionHeader(title: 'TAGS'),
                            const SizedBox(height: 4),
                            ...notesProvider.tagsWithCount.entries.map((entry) {
                              final isTagSelected = notesProvider.activeTag == entry.key;
                              return _TagTile(
                                key: ValueKey('tag_${entry.key}'),
                                tagName: entry.key,
                                count: entry.value,
                                isSelected: isTagSelected,
                                onTap: () {
                                  notesProvider.setActiveTag(isTagSelected ? null : entry.key);
                                },
                              );
                            }),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Bottom New Folder Action
          AnimatedContainer(
            duration: NotesConstants.themeAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: NotesTheme.divider(context),
                  width: 0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showNewFolderDialog(context),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.folder_badge_plus,
                        size: 16.0,
                        color: NotesTheme.accentGold,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'New Folder',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: NotesTheme.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'About Notes',
                  child: CupertinoButton(
                    key: const ValueKey('about_notes_btn'),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => AboutNotesDialog.show(context),
                    child: const AppIconBadge(size: 22.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context) async {
    final result = await showCupertinoDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddFolderDialog(),
    );

    if (result != null && result['name'] != null) {
      if (context.mounted) {
        context.read<FolderProvider>().createFolder(result['name']!);
      }
    }
  }

  void _showRenameDialog(BuildContext context, Folder folder) async {
    final result = await showCupertinoDialog<Map<String, String>>(
      context: context,
      builder: (_) => AddFolderDialog(
        initialName: folder.name,
        title: 'Rename Folder',
        actionLabel: 'Save',
      ),
    );

    if (result != null && result['name'] != null) {
      if (context.mounted) {
        context.read<FolderProvider>().renameFolder(folder.id, result['name']!);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: NotesTheme.textTertiary(context),
        ),
      ),
    );
  }
}

class _SidebarItemTile extends StatefulWidget {
  final Folder folder;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const _SidebarItemTile({
    super.key,
    required this.folder,
    required this.isSelected,
    required this.count,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = isDark
          ? const Color(0xFF4A3E1E)
          : NotesTheme.accentGold.withValues(alpha: 0.18);
    } else if (_isHovered) {
      backgroundColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    }

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
        onSecondaryTapUp: (details) {
          if (!widget.folder.isSystem && (widget.onRename != null || widget.onDelete != null)) {
            _showContextMenu(context, details.globalPosition);
          }
        },
        child: AnimatedScale(
          duration: NotesConstants.microAnimationDuration,
          curve: NotesConstants.defaultAnimationCurve,
          scale: _isPressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            height: 30,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.folder.iconData,
                  size: 15.0,
                  color: NotesTheme.accentGold,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: NotesConstants.microAnimationDuration,
                    curve: NotesConstants.defaultAnimationCurve,
                    style: TextStyle(
                      fontFamily: '.AppleSystemUIFont',
                      fontSize: 12.5,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: NotesTheme.textPrimary(context),
                    ),
                    child: Text(
                      widget.folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: NotesConstants.microAnimationDuration,
                  child: widget.count > 0
                      ? Text(
                          '${widget.count}',
                          key: ValueKey<int>(widget.count),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: NotesTheme.textTertiary(context),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.folder.name),
        actions: [
          if (widget.onRename != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onRename!();
              },
              child: const Text('Rename Folder'),
            ),
          if (widget.onDelete != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onDelete!();
              },
              child: const Text('Delete Folder'),
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

class _TagTile extends StatefulWidget {
  final String tagName;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagTile({
    super.key,
    required this.tagName,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TagTile> createState() => _TagTileState();
}

class _TagTileState extends State<_TagTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    Color backgroundColor = Colors.transparent;
    if (widget.isSelected) {
      backgroundColor = isDark
          ? const Color(0xFF4A3E1E)
          : NotesTheme.accentGold.withValues(alpha: 0.18);
    } else if (_isHovered) {
      backgroundColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    }

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
          scale: _isPressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            height: 28,
            margin: const EdgeInsets.symmetric(vertical: 1.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.number,
                  size: 13.0,
                  color: widget.isSelected
                      ? NotesTheme.accentGold
                      : NotesTheme.textSecondary(context),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: NotesConstants.microAnimationDuration,
                    curve: NotesConstants.defaultAnimationCurve,
                    style: TextStyle(
                      fontFamily: '.AppleSystemUIFont',
                      fontSize: 12.0,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: NotesTheme.textPrimary(context),
                    ),
                    child: Text(widget.tagName),
                  ),
                ),
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: NotesTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
