import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/utils/notes_utils.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';
import 'package:mac_notes_app/features/notes/services/notes_storage_service.dart';
import 'package:uuid/uuid.dart';

enum NotesViewMode { list, gallery }

/// Provider managing notes list, selection, CRUD, search, and rich editing.
class NotesProvider extends ChangeNotifier {
  final NotesStorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<Note> _notes = [];
  String? _selectedNoteId;
  String _searchQuery = '';
  String? _activeTag;
  NotesViewMode _viewMode = NotesViewMode.list;
  bool _isLoading = true;

  Timer? _saveDebounceTimer;

  NotesProvider({NotesStorageService? storageService})
      : _storageService = storageService ?? NotesStorageService() {
    loadNotes();
  }

  // Getters
  List<Note> get allNotes => List.unmodifiable(_notes);
  String? get selectedNoteId => _selectedNoteId;
  String get searchQuery => _searchQuery;
  String? get activeTag => _activeTag;
  NotesViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;

  Note? get selectedNote {
    if (_selectedNoteId == null) return null;
    try {
      return _notes.firstWhere((n) => n.id == _selectedNoteId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _storageService.loadNotes();

    if (_notes.isNotEmpty && _selectedNoteId == null) {
      _selectedNoteId = _notes.first.id;
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectNote(String? noteId) {
    if (_selectedNoteId != noteId) {
      _selectedNoteId = noteId;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveTag(String? tag) {
    _activeTag = tag;
    notifyListeners();
  }

  void setViewMode(NotesViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == NotesViewMode.list ? NotesViewMode.gallery : NotesViewMode.list;
    notifyListeners();
  }

  int countNotesInFolder(String folderId) {
    if (folderId == NotesConstants.allNotesFolderId) {
      return _notes.where((n) => n.folderId != NotesConstants.trashFolderId).length;
    } else if (folderId == NotesConstants.trashFolderId) {
      return _notes.where((n) => n.folderId == NotesConstants.trashFolderId).length;
    } else {
      return _notes.where((n) => n.folderId == folderId).length;
    }
  }

  Map<String, int> get tagsWithCount {
    final Map<String, int> counts = {};
    for (final note in _notes.where((n) => n.folderId != NotesConstants.trashFolderId)) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<Note> getFilteredNotes(String activeFolderId) {
    return _notes.where((note) {
      if (activeFolderId == NotesConstants.allNotesFolderId) {
        if (note.folderId == NotesConstants.trashFolderId) return false;
      } else if (activeFolderId == NotesConstants.trashFolderId) {
        if (note.folderId != NotesConstants.trashFolderId) return false;
      } else {
        if (note.folderId != activeFolderId) return false;
      }

      if (_activeTag != null && !note.tags.contains(_activeTag)) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesTitle = note.title.toLowerCase().contains(query);
        final matchesBody = note.body.toLowerCase().contains(query);
        final matchesTags = note.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesTitle && !matchesBody && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  Future<Note> createNote({
    required String folderId,
    String title = 'New Note',
    String body = '',
  }) async {
    final now = DateTime.now();
    final actualFolderId = folderId == NotesConstants.allNotesFolderId ||
            folderId == NotesConstants.trashFolderId
        ? NotesConstants.defaultNotesFolderId
        : folderId;

    final newNote = Note(
      id: _uuid.v4(),
      folderId: actualFolderId,
      title: title,
      body: body,
      isPinned: false,
      isLocked: false,
      checklists: const [],
      tables: const [],
      attachments: const [],
      createdAt: now,
      updatedAt: now,
    );

    _notes.insert(0, newNote);
    _selectedNoteId = newNote.id;
    await _storageService.saveNotes(_notes);
    notifyListeners();
    return newNote;
  }

  void updateNoteText(String noteId, String fullText) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final extractedTitle = NotesUtils.extractTitle(fullText);
    final lines = fullText.split('\n');
    final extractedBody = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    _notes[index] = _notes[index].copyWith(
      title: extractedTitle,
      body: extractedBody,
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _storageService.saveNotes(_notes);
    });
  }

  void updateNoteRichText(String noteId, {required String richTextJson, required String plainText}) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final extractedTitle = NotesUtils.extractTitle(plainText);
    final lines = plainText.split('\n');
    final extractedBody = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    _notes[index] = _notes[index].copyWith(
      title: extractedTitle,
      body: extractedBody,
      richTextJson: richTextJson,
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _storageService.saveNotes(_notes);
    });
  }

  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        isPinned: !_notes[index].isPinned,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveNotes(_notes);
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final note = _notes[index];
    if (note.folderId != NotesConstants.trashFolderId) {
      _notes[index] = note.copyWith(
        folderId: NotesConstants.trashFolderId,
        updatedAt: DateTime.now(),
      );
    } else {
      _notes.removeAt(index);
    }

    if (_selectedNoteId == noteId) {
      _selectedNoteId = _notes.isNotEmpty ? _notes.first.id : null;
    }

    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> restoreNote(String noteId, {String? targetFolderId}) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        folderId: targetFolderId ?? NotesConstants.defaultNotesFolderId,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveNotes(_notes);
      notifyListeners();
    }
  }

  Future<Note> duplicateNote(String noteId) async {
    final original = _notes.firstWhere((n) => n.id == noteId);
    final now = DateTime.now();

    final duplicate = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
    );

    _notes.insert(0, duplicate);
    _selectedNoteId = duplicate.id;
    await _storageService.saveNotes(_notes);
    notifyListeners();
    return duplicate;
  }

  Future<void> moveNote(String noteId, String newFolderId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        folderId: newFolderId,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveNotes(_notes);
      notifyListeners();
    }
  }

  Future<void> addChecklist(String noteId, {String text = 'Checklist Item'}) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final newItem = ChecklistItem(id: _uuid.v4(), text: text, isCompleted: false);
    final updatedChecklists = List<ChecklistItem>.from(_notes[index].checklists)..add(newItem);

    _notes[index] = _notes[index].copyWith(
      checklists: updatedChecklists,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> toggleChecklist(String noteId, String checklistId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final updatedChecklists = _notes[index].checklists.map((c) {
      if (c.id == checklistId) {
        return c.copyWith(isCompleted: !c.isCompleted);
      }
      return c;
    }).toList();

    _notes[index] = _notes[index].copyWith(
      checklists: updatedChecklists,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> updateChecklistText(String noteId, String checklistId, String newText) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final updatedChecklists = _notes[index].checklists.map((c) {
      if (c.id == checklistId) {
        return c.copyWith(text: newText);
      }
      return c;
    }).toList();

    _notes[index] = _notes[index].copyWith(
      checklists: updatedChecklists,
      updatedAt: DateTime.now(),
    );
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _storageService.saveNotes(_notes);
    });
    notifyListeners();
  }

  Future<void> removeChecklist(String noteId, String checklistId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final updatedChecklists =
        _notes[index].checklists.where((c) => c.id != checklistId).toList();

    _notes[index] = _notes[index].copyWith(
      checklists: updatedChecklists,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> addTable(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    final newTable = NoteTable.createDefault(_uuid.v4());
    final updatedTables = List<NoteTable>.from(_notes[index].tables)..add(newTable);

    _notes[index] = _notes[index].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> updateTableCell(
    String noteId,
    String tableId,
    int rowIndex,
    int colIndex,
    String value,
  ) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        final newCells = table.cells.map((r) => List<String>.from(r)).toList();
        if (rowIndex < newCells.length && colIndex < newCells[rowIndex].length) {
          newCells[rowIndex][colIndex] = value;
        }
        return table.copyWith(cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _storageService.saveNotes(_notes);
    });
    notifyListeners();
  }

  Future<void> addTableRow(String noteId, String tableId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        final newCells = table.cells.map((r) => List<String>.from(r)).toList();
        final newRow = List<String>.filled(table.colCount, '');
        newCells.add(newRow);
        return table.copyWith(rowCount: table.rowCount + 1, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> addTableColumn(String noteId, String tableId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        final newCells = table.cells.map((r) {
          final rowCopy = List<String>.from(r);
          rowCopy.add('');
          return rowCopy;
        }).toList();
        return table.copyWith(colCount: table.colCount + 1, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> removeTable(String noteId, String tableId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.where((t) => t.id != tableId).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> deleteTableRow(String noteId, String tableId, int rowIndex) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        if (table.rowCount <= 1) return table;
        if (rowIndex < 0 || rowIndex >= table.cells.length) return table;

        final newCells = table.cells.map((r) => List<String>.from(r)).toList();
        newCells.removeAt(rowIndex);
        return table.copyWith(rowCount: newCells.length, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> deleteTableColumn(String noteId, String tableId, int colIndex) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        if (table.colCount <= 1) return table;

        final newCells = table.cells.map((r) {
          final rowCopy = List<String>.from(r);
          if (colIndex >= 0 && colIndex < rowCopy.length) {
            rowCopy.removeAt(colIndex);
          }
          return rowCopy;
        }).toList();

        final newColCount = newCells.isNotEmpty ? newCells.first.length : (table.colCount - 1);
        return table.copyWith(colCount: newColCount, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> insertTableRow(String noteId, String tableId, int atIndex) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        final newCells = table.cells.map((r) => List<String>.from(r)).toList();
        final safeIndex = atIndex.clamp(0, newCells.length);
        newCells.insert(safeIndex, List<String>.filled(table.colCount, ''));
        return table.copyWith(rowCount: newCells.length, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> insertTableColumn(String noteId, String tableId, int atIndex) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedTables = _notes[noteIndex].tables.map((table) {
      if (table.id == tableId) {
        final newCells = table.cells.map((r) {
          final rowCopy = List<String>.from(r);
          final safeIndex = atIndex.clamp(0, rowCopy.length);
          rowCopy.insert(safeIndex, '');
          return rowCopy;
        }).toList();
        return table.copyWith(colCount: table.colCount + 1, cells: newCells);
      }
      return table;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      tables: updatedTables,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  // --- Code Block operations ---

  Future<void> addCodeBlock(String noteId, {String language = 'dart', String code = ''}) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final newBlock = NoteCodeBlock(
      id: const Uuid().v4(),
      language: language,
      code: code.isNotEmpty ? code : '// Write your $language code here\n',
    );

    final updated = List<NoteCodeBlock>.from(_notes[noteIndex].codeBlocks)..add(newBlock);

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      codeBlocks: updated,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> updateCodeBlockText(String noteId, String codeBlockId, String code) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updated = _notes[noteIndex].codeBlocks.map((cb) {
      if (cb.id == codeBlockId) {
        return cb.copyWith(code: code);
      }
      return cb;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      codeBlocks: updated,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> updateCodeBlockLanguage(String noteId, String codeBlockId, String language) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updated = _notes[noteIndex].codeBlocks.map((cb) {
      if (cb.id == codeBlockId) {
        return cb.copyWith(language: language);
      }
      return cb;
    }).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      codeBlocks: updated,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> removeCodeBlock(String noteId, String codeBlockId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updated = _notes[noteIndex].codeBlocks.where((cb) => cb.id != codeBlockId).toList();

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      codeBlocks: updated,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  // --- Lock operations ---

  Future<void> setNoteLock(String noteId, {required bool isLocked, String? password}) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    _notes[noteIndex] = _notes[noteIndex].copyWith(
      isLocked: isLocked,
      passwordHash: password?.hashCode.toString(),
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  bool verifyPassword(String noteId, String inputPassword) {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return false;
    final note = _notes[noteIndex];
    if (note.passwordHash == null) return true;
    return note.passwordHash == inputPassword.hashCode.toString();
  }

  // --- Attachment operations ---

  Future<void> addAttachment(String noteId, NoteAttachment attachment) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedAttachments = List<NoteAttachment>.from(_notes[noteIndex].attachments)..add(attachment);
    _notes[noteIndex] = _notes[noteIndex].copyWith(
      attachments: updatedAttachments,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  Future<void> removeAttachment(String noteId, String attachmentId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex == -1) return;

    final updatedAttachments = _notes[noteIndex].attachments.where((a) => a.id != attachmentId).toList();
    _notes[noteIndex] = _notes[noteIndex].copyWith(
      attachments: updatedAttachments,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveNotes(_notes);
    notifyListeners();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }
}
