/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Apple Notes styled dialog for configuring cross-device sync server URL and triggering Mac/iPad sync.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/auth_sync/providers/sync_provider.dart';
import 'package:mac_notes_app/features/folders/providers/folder_provider.dart';
import 'package:mac_notes_app/features/notes/providers/notes_provider.dart';
import 'package:provider/provider.dart';

/// Modal dialog allowing the user to configure the backend sync server URL and trigger two-way sync.
class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = context.read<SyncProvider>().serverUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return const Color(0xFF32D74B);
      case SyncStatus.syncing:
        return NotesTheme.accentGold;
      case SyncStatus.offline:
        return const Color(0xFFFF9F0A);
      case SyncStatus.error:
        return const Color(0xFFFF453A);
      case SyncStatus.idle:
        return const Color(0xFF8E8E93);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final notesProvider = context.read<NotesProvider>();
    final folderProvider = context.read<FolderProvider>();
    final isDark = NotesTheme.isDark(context);

    final lastSyncFormatted = syncProvider.lastSyncedAt != null
        ? DateFormat('MMM d, yyyy • h:mm:ss a').format(syncProvider.lastSyncedAt!)
        : 'Never synced';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF242428) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(
          color: NotesTheme.divider(context),
          width: 0.8,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: NotesTheme.accentGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9.0),
                    ),
                    child: const Icon(
                      CupertinoIcons.cloud_upload,
                      color: NotesTheme.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cross-Device Sync (Mac & iPad)',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: NotesTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offline-first storage with Docker Django/MongoDB sync',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: NotesTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'SYNC SERVER API URL',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: NotesTheme.textTertiary(context),
                ),
              ),
              const SizedBox(height: 6),
              CupertinoTextField(
                controller: _urlController,
                placeholder: 'http://192.168.1.x:8000/api',
                style: TextStyle(
                  color: NotesTheme.textPrimary(context),
                  fontSize: 13.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
                decoration: BoxDecoration(
                  color: NotesTheme.searchBackground(context),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: NotesTheme.divider(context),
                    width: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'On Mac use http://127.0.0.1:8000/api. On iPad over Wi-Fi, enter your Mac\'s LAN IP (e.g. http://192.168.1.50:8000/api).',
                style: TextStyle(
                  fontSize: 11.5,
                  color: NotesTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1B1E) : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(syncProvider.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncProvider.statusMessage ?? 'Ready to sync.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: NotesTheme.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last synced: $lastSyncFormatted',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: NotesTheme.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: NotesTheme.textSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    color: isDark ? const Color(0xFF38383D) : const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(7.0),
                    onPressed: syncProvider.isSyncing
                        ? null
                        : () async {
                            await syncProvider.checkConnection(
                              customUrl: _urlController.text,
                            );
                          },
                    child: Text(
                      'Test Connection',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: NotesTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    color: NotesTheme.accentGold,
                    borderRadius: BorderRadius.circular(7.0),
                    onPressed: syncProvider.isSyncing
                        ? null
                        : () async {
                            await syncProvider.setServerUrl(_urlController.text);
                            await syncProvider.syncNow(
                              notesProvider: notesProvider,
                              folderProvider: folderProvider,
                            );
                          },
                    child: Text(
                      syncProvider.isSyncing ? 'Syncing...' : 'Sync Now',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
