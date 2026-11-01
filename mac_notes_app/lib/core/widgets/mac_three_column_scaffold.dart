import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/core/widgets/mac_toolbar.dart';
import 'package:mac_notes_app/features/folders/presentation/sidebar_view.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/presentation/editor_view.dart';
import 'package:mac_notes_app/features/notes/presentation/notes_gallery_view.dart';
import 'package:mac_notes_app/features/notes/presentation/notes_list_view.dart';
import 'package:mac_notes_app/features/notes/presentation/widgets/note_lock_dialog.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// Primary 3-Column macOS Window Scaffold matching Apple Notes.
class MacThreeColumnScaffold extends StatefulWidget {
  const MacThreeColumnScaffold({super.key});

  @override
  State<MacThreeColumnScaffold> createState() => _MacThreeColumnScaffoldState();
}

class _MacThreeColumnScaffoldState extends State<MacThreeColumnScaffold> {
  bool _showFormatMenu = false;

  @override
  Widget build(BuildContext context) {
    final folderProvider = context.watch<FolderProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final dividerColor = NotesTheme.divider(context);

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
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: NotesTheme.editorBackground(context),
          body: Column(
            children: [
              // 1. Unified macOS Toolbar
              MacToolbar(
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
                onAttachMedia: () => _handlePickAttachment(context, notesProvider),
                onToggleLock: () => _handleToggleLock(context, notesProvider),
              ),

              // 2. Three-Column Content Body
              Expanded(
                child: Row(
                  children: [
                    // Column 1: Sidebar (Folders & Accounts)
                    if (!folderProvider.isSidebarCollapsed) ...[
                      const SizedBox(
                        width: NotesConstants.defaultSidebarWidth,
                        child: SidebarView(),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                    ],

                    // Column 2: Notes List or Gallery View
                    if (notesProvider.viewMode == NotesViewMode.list) ...[
                      const SizedBox(
                        width: NotesConstants.defaultListWidth,
                        child: NotesListView(),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                    ],

                    // Column 3: Note Editor (or full gallery view when in gallery mode)
                    Expanded(
                      child: notesProvider.viewMode == NotesViewMode.gallery
                          ? const NotesGalleryView()
                          : EditorView(
                              showFormatMenu: _showFormatMenu,
                              onCloseFormatMenu: () {
                                setState(() => _showFormatMenu = false);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
