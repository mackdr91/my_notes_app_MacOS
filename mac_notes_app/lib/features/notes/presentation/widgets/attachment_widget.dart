import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Card preview widget for note attachments (images, PDFs, documents).
class AttachmentWidget extends StatelessWidget {
  final NoteAttachment attachment;
  final VoidCallback onDelete;

  const AttachmentWidget({
    super.key,
    required this.attachment,
    required this.onDelete,
  });

  bool get _isImage {
    final type = attachment.fileType.toLowerCase();
    return type.contains('png') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('gif') ||
        type.contains('webp');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final file = File(attachment.localPath);
    final exists = file.existsSync();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: NotesTheme.divider(context), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isImage && exists)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(context),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  _isImage ? CupertinoIcons.photo : CupertinoIcons.doc,
                  size: 20,
                  color: NotesTheme.accentGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: NotesTheme.textPrimary(context),
                        ),
                      ),
                      Text(
                        _formatSize(attachment.fileSize),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: NotesTheme.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(24, 24),
                  onPressed: onDelete,
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 15,
                    color: NotesTheme.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: 90,
      color: Colors.black12,
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 32,
          color: NotesTheme.textTertiary(context),
        ),
      ),
    );
  }
}
