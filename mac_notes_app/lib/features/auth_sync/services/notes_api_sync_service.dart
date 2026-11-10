/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Sync service connecting Flutter macOS and iPadOS clients to the Django REST Framework + MongoDB backend.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mac_notes_app/features/folders/models/folder_model.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Sync service connecting Flutter clients to the Django REST Framework + MongoDB backend.
class NotesApiSyncService {
  String _baseUrl;
  final http.Client _client;

  NotesApiSyncService({
    String baseUrl = 'http://127.0.0.1:8000/api',
    http.Client? client,
  })  : _baseUrl = _normalizeUrl(baseUrl),
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = _normalizeUrl(newUrl);
  }

  static String _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'http://127.0.0.1:8000/api';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  /// Checks if the Django backend is reachable and healthy.
  Future<bool> checkHealth({String? overrideUrl}) async {
    final targetBase = overrideUrl != null ? _normalizeUrl(overrideUrl) : _baseUrl;
    try {
      final uri = Uri.parse('$targetBase/health/');
      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Performs two-way batch sync of local notes and folders with MongoDB via Django API.
  Future<Map<String, dynamic>> syncBatch({
    required List<Note> notes,
    required List<Folder> folders,
    DateTime? lastSync,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/sync/');
      final payload = {
        'notes': notes.map((n) => n.toJson()).toList(),
        'folders': folders.map((f) => f.toJson()).toList(),
        'lastSyncTimestamp': lastSync?.toIso8601String(),
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'error',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'status': 'offline',
        'error': e.toString(),
      };
    }
  }
}
