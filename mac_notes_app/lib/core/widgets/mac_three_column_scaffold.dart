/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Responsive multi-column scaffold supporting 3-column macOS/iPad Landscape, 2-column iPad Portrait/Split-View, and compact Slide-Over with slide-over drawer.
 */

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/utils/platform_layout.dart';
import 'package:mac_notes_app/core/widgets/mac_toolbar.dart';
import 'package:mac_notes_app/features/folders/presentation/sidebar_view.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/editor_view.dart';
import 'package:mac_notes_app/features/notes/presentation/notes_gallery_view.dart';
import 'package:mac_notes_app/features/notes/presentation/notes_list_view.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/note_lock_dialog.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:mac_notes_app/features/theme/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Primary responsive multi-column scaffold matching Apple Notes on macOS and iPadOS.
class MacThreeColumnScaffold extends StatefulWidget {
  const MacThreeColumnScaffold({super.key});

  @override
  State<MacThreeColumnScaffold> createState() => _MacThreeColumnScaffoldState();
}

class _MacThreeColumnScaffoldState extends State<MacThreeColumnScaffold> {
  bool _showFormatMenu = false;
  bool _compactShowingList = false;
  String? _lastSelectedNoteId;

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final dividerColor = NotesTheme.divider(context);
    final isListMode = notesProvider.viewMode == NotesViewMode.list;

    // Automatically navigate to the editor when a user selects or creates a note in compact mode
    if (notesProvider.selectedNoteId != _lastSelectedNoteId) {
      _lastSelectedNoteId = notesProvider.selectedNoteId;
      if (_lastSelectedNoteId != null) {
        _compactShowingList = false;
      }
    }

    return CallbackShortcuts(
      bindings: {
        // Cmd+N: New Note
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
          notesProvider.createNote(folderId: folderProvider.selectedFolderId);
        },
        // Cmd+Shift+N: New Folder
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true): () {
          folderProvider.createFolder('New Folder');
        },
        // Cmd+Delete: Delete Selected Note
        const SingleActivator(LogicalKeyboardKey.backspace, meta: true): () {
          if (notesProvider.selectedNoteId != null) {
            notesProvider.deleteNote(notesProvider.selectedNoteId!);
          }
        },
        // Cmd+1: List View
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () {
          notesProvider.setViewMode(NotesViewMode.list);
        },
        // Cmd+2: Gallery View
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () {
          notesProvider.setViewMode(NotesViewMode.gallery);
        },
        // Cmd+Shift+T: Cycle Theme Mode
        const SingleActivator(LogicalKeyboardKey.keyT, meta: true, shift: true): () {
          context.read<ThemeProvider>().cycleThemeMode();
        },
        // Cmd+Shift+C: Insert Code Block
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true): () {
          if (notesProvider.selectedNoteId != null) {
            notesProvider.addCodeBlock(notesProvider.selectedNoteId!);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sizeClass = PlatformLayout.sizeClassForWidth(constraints.maxWidth);
            final isWide = sizeClass == ScreenSizeClass.wide;
            final isCompact = sizeClass == ScreenSizeClass.compact;
            final showOverlayDrawer = !isWide && !folderProvider.isSidebarCollapsed;

            return Scaffold(
              backgroundColor: NotesTheme.editorBackground(context),
              body: Column(
                children: [
                  // 1. Unified Platform-Adaptive Toolbar
                  MacToolbar(
                    showCompactBackButton:
                        isCompact && isListMode && !_compactShowingList,
                    onCompactBack: () {
                      setState(() {
                        _compactShowingList = true;
                      });
                    },
                    onToggleChecklist: () {
                      if (notesProvider.selectedNoteId != null) {
                        notesProvider.addChecklist(notesProvider.selectedNoteId!);
                      }
                    },
                    onInsertTable: () {
                      if (notesProvider.selectedNoteId != null) {
                        notesProvider.addTable(notesProvider.selectedNoteId!);
                      }
                    },
                    onToggleFormatMenu: () {
                      setState(() {
                        _showFormatMenu = !_showFormatMenu;
                      });
                    },
                    onInsertCodeBlock: () {
                      if (notesProvider.selectedNoteId != null) {
                        notesProvider.addCodeBlock(notesProvider.selectedNoteId!);
                      }
                    },
                    onAttachMedia: () => _handlePickAttachment(context, notesProvider),
                    onToggleLock: () => _handleToggleLock(context, notesProvider),
                  ),

                  // 2. Responsive Multi-Column Content Body + Optional iPad Slide-Over Sidebar Drawer
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            // Column 1: Inline Sidebar (Shown inline on Wide viewports)
                            _AnimatedCollapsibleColumn(
                              isVisible: isWide && !folderProvider.isSidebarCollapsed,
                              width: NotesConstants.defaultSidebarWidth,
                              dividerColor: dividerColor,
                              child: const SidebarView(),
                            ),

                            // Column 2: Notes List View (Inline on Wide/Medium; full-width in Compact list state)
                            if (!isCompact)
                              _AnimatedCollapsibleColumn(
                                isVisible: isListMode,
                                width: sizeClass == ScreenSizeClass.medium
                                    ? 260.0
                                    : NotesConstants.defaultListWidth,
                                dividerColor: dividerColor,
                                child: const NotesListView(),
                              ),

                            // Column 3: Main Content Area (Editor, Gallery, or Compact List)
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: NotesConstants.contentAnimationDuration,
                                switchInCurve: NotesConstants.defaultAnimationCurve,
                                switchOutCurve: NotesConstants.exitAnimationCurve,
                                transitionBuilder: (child, animation) {
                                  final scaleAnimation = Tween<double>(
                                    begin: 0.985,
                                    end: 1.0,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: scaleAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: notesProvider.viewMode == NotesViewMode.gallery
                                    ? const NotesGalleryView(key: ValueKey('gallery_view'))
                                    : (isCompact && _compactShowingList
                                        ? const NotesListView(
                                            key: ValueKey('compact_list_view'),
                                          )
                                        : EditorView(
                                            key: const ValueKey('editor_view'),
                                            showFormatMenu: _showFormatMenu,
                                            onCloseFormatMenu: () {
                                              setState(() => _showFormatMenu = false);
                                            },
                                          )),
                              ),
                            ),
                          ],
                        ),

                        // Slide-over Sidebar Drawer for iPad Portrait / Split-View / Compact widths
                        if (!isWide)
                          IgnorePointer(
                            ignoring: !showOverlayDrawer,
                            child: AnimatedOpacity(
                              duration: NotesConstants.contentAnimationDuration,
                              curve: NotesConstants.defaultAnimationCurve,
                              opacity: showOverlayDrawer ? 1.0 : 0.0,
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    key: const ValueKey('sidebar_drawer_scrim'),
                                    onTap: () => folderProvider.setSidebarCollapsed(true),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.32),
                                    ),
                                  ),
                                  AnimatedSlide(
                                    duration: NotesConstants.layoutAnimationDuration,
                                    curve: NotesConstants.layoutAnimationCurve,
                                    offset: showOverlayDrawer
                                        ? Offset.zero
                                        : const Offset(-1.0, 0.0),
                                    child: SizedBox(
                                      width: NotesConstants.defaultSidebarWidth + 20,
                                      height: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: NotesTheme.sidebarBackground(context),
                                          border: Border(
                                            right: BorderSide(
                                              color: dividerColor,
                                              width: 0.8,
                                            ),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 16,
                                              offset: const Offset(4, 0),
                                            ),
                                          ],
                                        ),
                                        child: const SidebarView(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePickAttachment(BuildContext context, NotesProvider provider) async {
    final noteId = provider.selectedNoteId;
    if (noteId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        if (path != null) {
          final attachment = NoteAttachment(
            id: const Uuid().v4(),
            name: file.name,
            fileType: file.extension ?? 'file',
            localPath: path,
            fileSize: file.size,
          );
          await provider.addAttachment(noteId, attachment);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Attachment Error'),
            content: Text('Failed to attach file: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleToggleLock(BuildContext context, NotesProvider provider) async {
    final note = provider.selectedNote;
    if (note == null) return;

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (_) => NoteLockDialog(isCurrentlyLocked: note.isLocked),
    );

    if (result != null) {
      if (note.isLocked) {
        if (provider.verifyPassword(note.id, result)) {
          await provider.setNoteLock(note.id, isLocked: false);
        } else if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Incorrect Password'),
              content: const Text('The password entered was incorrect.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } else {
        await provider.setNoteLock(note.id, isLocked: true, password: result);
      }
    }
  }
}

/// Reusable animated column wrapper that smoothly collapses/expands its width
/// and opacity without causing internal child layout reflow or flex overflow.
class _AnimatedCollapsibleColumn extends StatelessWidget {
  final bool isVisible;
  final double width;
  final Color dividerColor;
  final Widget child;

  const _AnimatedCollapsibleColumn({
    required this.isVisible,
    required this.width,
    required this.dividerColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        duration: NotesConstants.layoutAnimationDuration,
        curve: NotesConstants.layoutAnimationCurve,
        alignment: Alignment.centerLeft,
        widthFactor: isVisible ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: NotesConstants.contentAnimationDuration,
          curve: NotesConstants.defaultAnimationCurve,
          opacity: isVisible ? 1.0 : 0.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                child: child,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
