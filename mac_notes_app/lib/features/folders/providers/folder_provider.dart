/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: State management for Folders, Sidebar navigation, and cross-device folder synchronization.
 */

import 'package:flutter/foundation.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/features/folders/models/folder_model.dart';
import 'package:mac_notes_app/features/folders/services/folder_storage_service.dart';
import 'package:uuid/uuid.dart';

/// State management for Folders and Sidebar navigation.
class FolderProvider extends ChangeNotifier {
  final FolderStorageService _storageService;
  final Uuid _uuid = const Uuid();

  List<Folder> _folders = [];
  String _selectedFolderId = NotesConstants.allNotesFolderId;
  bool _isSidebarCollapsed = false;
  bool _isLoading = true;

  FolderProvider({FolderStorageService? storageService})
      : _storageService = storageService ?? FolderStorageService() {
    loadFolders();
  }

  // Getters
  List<Folder> get folders => List.unmodifiable(_folders);
  String get selectedFolderId => _selectedFolderId;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  bool get isLoading => _isLoading;

  Folder? get selectedFolder {
    try {
      return _folders.firstWhere((f) => f.id == _selectedFolderId);
    } catch (_) {
      return _folders.isNotEmpty ? _folders.first : null;
    }
  }

  Folder? get quickNotesFolder =>
      _folders.cast<Folder?>().firstWhere(
            (f) => f?.id == NotesConstants.quickNotesFolderId,
            orElse: () => null,
          );

  Folder? get trashFolder =>
      _folders.cast<Folder?>().firstWhere(
            (f) => f?.id == NotesConstants.trashFolderId,
            orElse: () => null,
          );

  List<Folder> get iCloudFolders => _folders
      .where((f) =>
          f.account == NotesConstants.accountICloud &&
          f.id != NotesConstants.quickNotesFolderId &&
          f.id != NotesConstants.trashFolderId)
      .toList();

  List<Folder> get onMyMacFolders => _folders
      .where((f) => f.account == NotesConstants.accountOnMyMac)
      .toList();

  Future<void> loadFolders() async {
    _isLoading = true;
    notifyListeners();

    _folders = await _storageService.loadFolders();
    _selectedFolderId = await _storageService.loadActiveFolderId();

    if (!_folders.any((f) => f.id == _selectedFolderId)) {
      _selectedFolderId = NotesConstants.allNotesFolderId;
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (_isSidebarCollapsed != collapsed) {
      _isSidebarCollapsed = collapsed;
      notifyListeners();
    }
  }

  Future<void> selectFolder(String folderId) async {
    if (_selectedFolderId != folderId) {
      _selectedFolderId = folderId;
      await _storageService.saveActiveFolderId(folderId);
      notifyListeners();
    }
  }

  Future<Folder> createFolder(
    String name, {
    String account = NotesConstants.accountICloud,
    String? parentId,
  }) async {
    final now = DateTime.now();
    final newFolder = Folder(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'New Folder' : name.trim(),
      account: account,
      parentId: parentId,
      isSystem: false,
      iconType: 'folder',
      createdAt: now,
      updatedAt: now,
    );

    _folders.add(newFolder);
    await _storageService.saveFolders(_folders);
    await selectFolder(newFolder.id);
    notifyListeners();
    return newFolder;
  }

  Future<void> renameFolder(String folderId, String newName) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1 && !_folders[index].isSystem) {
      _folders[index] = _folders[index].copyWith(
        name: newName.trim().isEmpty ? _folders[index].name : newName.trim(),
        updatedAt: DateTime.now(),
      );
      await _storageService.saveFolders(_folders);
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String folderId) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1 && !_folders[index].isSystem) {
      _folders.removeAt(index);
      await _storageService.saveFolders(_folders);

      if (_selectedFolderId == folderId) {
        await selectFolder(NotesConstants.allNotesFolderId);
      } else {
        notifyListeners();
      }
    }
  }

  /// Merges remote folders returned by the sync server using Last-Write-Wins (updatedAt).
  Future<void> mergeSyncedFolders(List<Folder> remoteFolders) async {
    if (remoteFolders.isEmpty) return;

    final Map<String, Folder> byId = {
      for (final f in _folders) f.id: f,
    };

    for (final remote in remoteFolders) {
      final existing = byId[remote.id];
      if (existing == null || !remote.updatedAt.isBefore(existing.updatedAt)) {
        byId[remote.id] = remote;
      }
    }

    _folders = byId.values.toList();
    await _storageService.saveFolders(_folders);
    notifyListeners();
  }
}
