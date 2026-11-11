/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Provider managing backend sync server URL, connection health checks, and two-way cross-device synchronization.
 */

import 'package:flutter/foundation.dart';
import 'package:lusid/features/auth_sync/services/notes_api_sync_service.dart';
import 'package:lusid/features/folders/models/folder_model.dart';
import 'package:lusid/features/folders/providers/folder_provider.dart';
import 'package:lusid/features/notes/models/note_model.dart';
import 'package:lusid/features/notes/providers/notes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus { idle, syncing, synced, offline, error }

/// Provider orchestrating cross-device synchronization between Mac, iPad, and the Django/MongoDB backend.
class SyncProvider extends ChangeNotifier {
  static const String _serverUrlPrefKey = 'notes_sync_server_url_v1';
  static const String _lastSyncPrefKey = 'notes_last_sync_iso_v1';

  final NotesApiSyncService _syncService;
  SyncStatus _status = SyncStatus.idle;
  String _serverUrl = 'http://127.0.0.1:8000/api';
  DateTime? _lastSyncedAt;
  String? _statusMessage;

  SyncProvider({NotesApiSyncService? syncService})
    : _syncService = syncService ?? NotesApiSyncService() {
    _loadSettings();
  }

  SyncStatus get status => _status;
  String get serverUrl => _serverUrl;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get statusMessage => _statusMessage;
  bool get isSyncing => _status == SyncStatus.syncing;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_serverUrlPrefKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _serverUrl = savedUrl.trim();
        _syncService.updateBaseUrl(_serverUrl);
      }

      final lastSyncIso = prefs.getString(_lastSyncPrefKey);
      if (lastSyncIso != null) {
        _lastSyncedAt = DateTime.tryParse(lastSyncIso);
      }
      notifyListeners();
    } catch (_) {
      // Fallback to defaults if SharedPreferences is unavailable
    }
  }

  /// Updates and persists the backend server URL (e.g. LAN IP for iPad sync or cloud URL).
  Future<void> setServerUrl(String newUrl) async {
    final cleaned = newUrl.trim().isEmpty
        ? 'http://127.0.0.1:8000/api'
        : newUrl.trim();
    _serverUrl = cleaned;
    _syncService.updateBaseUrl(_serverUrl);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlPrefKey, _serverUrl);
    } catch (_) {}
  }

  /// Checks whether the configured backend URL responds to `/health/`.
  Future<bool> checkConnection({String? customUrl}) async {
    _status = SyncStatus.syncing;
    _statusMessage = 'Checking server connection...';
    notifyListeners();

    if (customUrl != null && customUrl.trim().isNotEmpty) {
      await setServerUrl(customUrl);
    }

    final healthy = await _syncService.checkHealth();
    if (healthy) {
      _status = SyncStatus.synced;
      _statusMessage = 'Connected to sync server.';
    } else {
      _status = SyncStatus.offline;
      _statusMessage = 'Server unreachable (working offline).';
    }
    notifyListeners();
    return healthy;
  }

  /// Performs a two-way batch sync of notes and folders with the backend server.
  Future<bool> syncNow({
    required NotesProvider notesProvider,
    required FolderProvider folderProvider,
  }) async {
    if (_status == SyncStatus.syncing) return false;

    _status = SyncStatus.syncing;
    _statusMessage = 'Syncing notes & folders...';
    notifyListeners();

    final result = await _syncService.syncBatch(
      notes: notesProvider.allNotes,
      folders: folderProvider.folders,
      lastSync: _lastSyncedAt,
    );

    if (result['status'] == 'success') {
      final rawNotes = result['notes'];
      if (rawNotes is List) {
        final remoteNotes = rawNotes
            .whereType<Map<String, dynamic>>()
            .map(Note.fromJson)
            .toList();
        await notesProvider.mergeSyncedNotes(remoteNotes);
      }

      final rawFolders = result['folders'];
      if (rawFolders is List) {
        final remoteFolders = rawFolders
            .whereType<Map<String, dynamic>>()
            .map(Folder.fromJson)
            .toList();
        await folderProvider.mergeSyncedFolders(remoteFolders);
      }

      _lastSyncedAt = DateTime.now();
      _status = SyncStatus.synced;
      _statusMessage =
          'Synced ${notesProvider.allNotes.length} notes across devices.';

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _lastSyncPrefKey,
          _lastSyncedAt!.toIso8601String(),
        );
      } catch (_) {}

      notifyListeners();
      return true;
    } else if (result['status'] == 'offline') {
      _status = SyncStatus.offline;
      _statusMessage = 'Offline mode — local changes saved on device.';
      notifyListeners();
      return false;
    } else {
      _status = SyncStatus.error;
      _statusMessage = 'Sync error (${result['statusCode'] ?? 'unknown'}).';
      notifyListeners();
      return false;
    }
  }
}
