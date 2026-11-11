// Author: Domonick Mack
// Date: 2026-11-10
// Description: Local persistence service for custom folders using SharedPreferences.

import 'dart:convert';

import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/features/folders/models/folder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles local storage persistence for Folders.
class FolderStorageService {
  Future<List<Folder>> loadFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJsonString = prefs.getString(
        NotesConstants.foldersStorageKey,
      );

      if (foldersJsonString == null || foldersJsonString.isEmpty) {
        final defaultFolders = Folder.defaultFolders;
        await saveFolders(defaultFolders);
        return defaultFolders;
      }

      final List<dynamic> decoded =
          jsonDecode(foldersJsonString) as List<dynamic>;
      return decoded
          .map((item) => Folder.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return Folder.defaultFolders;
    }
  }

  Future<void> saveFolders(List<Folder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(folders.map((f) => f.toJson()).toList());
    await prefs.setString(NotesConstants.foldersStorageKey, encoded);
  }

  Future<String> loadActiveFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(NotesConstants.activeFolderKey) ??
        NotesConstants.allNotesFolderId;
  }

  Future<void> saveActiveFolderId(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NotesConstants.activeFolderKey, folderId);
  }
}
