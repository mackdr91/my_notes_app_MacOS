import 'package:flutter/cupertino.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';

/// Modal dialog matching macOS dialogs to create or rename folders.
class AddFolderDialog extends StatefulWidget {
  final String? initialName;
  final String title;
  final String actionLabel;

  const AddFolderDialog({
    super.key,
    this.initialName,
    this.title = 'New Folder',
    this.actionLabel = 'Create',
  });

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  late final TextEditingController _controller;
  final String _selectedAccount = NotesConstants.accountICloud;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _controller,
              autofocus: true,
              placeholder: 'Folder Name',
              style: TextStyle(
                color: NotesTheme.textPrimary(context),
                fontSize: 13.0,
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(context).pop({'name': val.trim(), 'account': _selectedAccount});
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop({'name': name, 'account': _selectedAccount});
            }
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
