import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';
import 'package:mac_notes_app/features/notes/models/note_model.dart';

/// Interactive circular checklist item matching Apple Notes.
class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onTextChanged,
    required this.onDelete,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  late final TextEditingController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(covariant ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text && _controller.text != widget.item.text) {
      _controller.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => widget.onToggle(!widget.item.isCompleted),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.item.isCompleted ? NotesTheme.accentGold : Colors.transparent,
                  border: Border.all(
                    color: widget.item.isCompleted
                        ? NotesTheme.accentGold
                        : NotesTheme.textTertiary(context),
                    width: 1.5,
                  ),
                ),
                child: widget.item.isCompleted
                    ? const Icon(
                        CupertinoIcons.checkmark,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: null,
                style: TextStyle(
                  fontSize: 14.5,
                  color: widget.item.isCompleted
                      ? NotesTheme.textTertiary(context)
                      : NotesTheme.textPrimary(context),
                  decoration: widget.item.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                onChanged: widget.onTextChanged,
              ),
            ),
            if (_isHovered)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(20, 20),
                onPressed: widget.onDelete,
                child: Icon(
                  CupertinoIcons.clear_circled,
                  size: 15,
                  color: NotesTheme.textTertiary(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
