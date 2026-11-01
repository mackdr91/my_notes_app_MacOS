import 'dart:convert';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting notes locally in SharedPreferences.
class NotesStorageService {
  Future<List<Note>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(NotesConstants.notesStorageKey);

      if (notesJson == null || notesJson.isEmpty) {
        final initialNotes = _generateInitialNotes();
        await saveNotes(initialNotes);
        return initialNotes;
      }

      final List<dynamic> decoded = jsonDecode(notesJson) as List<dynamic>;
      return decoded.map((item) => Note.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _generateInitialNotes();
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(NotesConstants.notesStorageKey, encoded);
  }

  List<Note> _generateInitialNotes() {
    final now = DateTime.now();

    return [
      Note(
        id: 'seed_note_1',
        folderId: NotesConstants.defaultNotesFolderId,
        title: 'Welcome to Apple Notes for Mac',
        body: 'This is an exact replica of the Apple Notes macOS desktop app.\n\n'
            'Key Features Built-In:\n'
            '• 3-Column macOS Desktop Navigation (Sidebar, Note List, and Rich Editor)\n'
            '• First-line auto Title formatting\n'
            '• Pinned notes with amber pin badges\n'
            '• Native search and folder organization\n'
            '• Interactive checklists and expandable data tables\n'
            '• Keyboard shortcuts: Cmd+N (New Note), Cmd+Shift+N (New Folder), Cmd+F (Find)',
        tags: const ['welcome', 'macOS', 'guide'],
        isPinned: true,
        isLocked: false,
        checklists: const [
          ChecklistItem(id: 'c1', text: 'Explore the 3-column macOS split view', isCompleted: true),
          ChecklistItem(id: 'c2', text: 'Create a new note with Cmd+N or toolbar compose', isCompleted: false),
          ChecklistItem(id: 'c3', text: 'Try toggling dark mode in macOS system settings', isCompleted: false),
          ChecklistItem(id: 'c4', text: 'Add your own custom folders and tags', isCompleted: false),
        ],
        tables: const [
          NoteTable(
            id: 't1',
            rowCount: 3,
            colCount: 3,
            cells: [
              ['Feature', 'Status', 'Platform'],
              ['3-Column Scaffold', 'Complete', 'macOS Desktop'],
              ['Interactive Checklists', 'Complete', 'macOS Desktop'],
            ],
          ),
        ],
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      Note(
        id: 'seed_note_2',
        folderId: 'work_folder',
        title: 'Sprint 24 Engineering Deliverables',
        body: 'Reviewing current milestones and core architecture:\n\n'
            '1. Django REST Framework backend models for MongoDB synchronization.\n'
            '2. Firebase Authentication token verification pipeline.\n'
            '3. Offline-first local persistence ensuring zero-latency note taking.\n'
            '4. Full keyboard navigation and shortcut handling.',
        tags: const ['work', 'engineering', 'sprint'],
        isPinned: false,
        isLocked: false,
        checklists: const [
          ChecklistItem(id: 'c5', text: 'Define MongoDB collections schema', isCompleted: true),
          ChecklistItem(id: 'c6', text: 'Setup DRF viewsets with explicit validation', isCompleted: true),
          ChecklistItem(id: 'c7', text: 'Verify offline queue synchronization', isCompleted: false),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Note(
        id: 'seed_note_3',
        folderId: NotesConstants.quickNotesFolderId,
        title: 'Quick Brainstorm: App Customizations',
        body: 'Ideas to customize this foundation once complete:\n\n'
            '- Custom markdown export and PDF compilation\n'
            '- Global menu bar quick note popover\n'
            '- Custom tag hierarchy with color coding\n'
            '- Biometric Touch ID lock integration',
        tags: const ['ideas', 'customizations'],
        isPinned: false,
        isLocked: false,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Note(
        id: 'seed_note_4',
        folderId: 'personal_folder',
        title: 'Weekend Yosemite Hiking Packing List',
        body: 'Essential gear for the weekend trip:\n\n'
            'Ensure all permits and passes are downloaded offline before leaving reception.',
        tags: const ['personal', 'travel'],
        isPinned: false,
        isLocked: false,
        checklists: const [
          ChecklistItem(id: 'c8', text: 'Hiking boots & wool socks', isCompleted: true),
          ChecklistItem(id: 'c9', text: 'Water filter & 3L hydration bladder', isCompleted: true),
          ChecklistItem(id: 'c10', text: 'First aid kit & headlamp', isCompleted: true),
          ChecklistItem(id: 'c11', text: 'National park wilderness permit', isCompleted: false),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
