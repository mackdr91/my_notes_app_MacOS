import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mac_notes_app/features/folders/models/folder_model.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Sync service connecting Flutter macOS desktop client to the Django REST Framework + MongoDB backend.
class NotesApiSyncService {
  final String baseUrl;
  final http.Client _client;

  NotesApiSyncService({
    this.baseUrl = 'http://127.0.0.1:8000/api',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Checks if the Django backend is reachable and healthy
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health/');
      final response = await _client.get(uri).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Performs batch sync of local notes and folders to MongoDB via Django API
  Future<Map<String, dynamic>> syncBatch({
    required List<Note> notes,
    required List<Folder> folders,
    DateTime? lastSync,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/sync/');
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
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'statusCode': response.statusCode};
      }
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }
}
