import 'package:flutter/cupertino.dart';
import 'package:lusid/core/theme/notes_theme.dart';

/// Modal dialog to set, change, or remove password lock for a note.
class NoteLockDialog extends StatefulWidget {
  final bool isCurrentlyLocked;

  const NoteLockDialog({super.key, required this.isCurrentlyLocked});

  @override
  State<NoteLockDialog> createState() => _NoteLockDialogState();
}

class _NoteLockDialogState extends State<NoteLockDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.isCurrentlyLocked ? 'Remove Password Lock' : 'Lock Note'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          children: [
            Text(
              widget.isCurrentlyLocked
                  ? 'Enter the password to remove the lock on this note.'
                  : 'Set a password to protect this note from unauthorized access.',
              style: TextStyle(
                fontSize: 12.5,
                color: NotesTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 12.0),
            CupertinoTextField(
              controller: _passwordController,
              autofocus: true,
              obscureText: true,
              placeholder: 'Password',
              style: TextStyle(
                color: NotesTheme.textPrimary(context),
                fontSize: 13.0,
              ),
            ),
            if (!widget.isCurrentlyLocked) ...[
              const SizedBox(height: 8.0),
              CupertinoTextField(
                controller: _confirmController,
                obscureText: true,
                placeholder: 'Verify Password',
                style: TextStyle(
                  color: NotesTheme.textPrimary(context),
                  fontSize: 13.0,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8.0),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontSize: 11.5,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final pass = _passwordController.text;
            if (pass.isEmpty) {
              setState(() => _errorMessage = 'Password cannot be blank.');
              return;
            }
            if (!widget.isCurrentlyLocked && pass != _confirmController.text) {
              setState(() => _errorMessage = 'Passwords do not match.');
              return;
            }
            Navigator.of(context).pop(pass);
          },
          child: Text(widget.isCurrentlyLocked ? 'Unlock' : 'Set Lock'),
        ),
      ],
    );
  }
}
