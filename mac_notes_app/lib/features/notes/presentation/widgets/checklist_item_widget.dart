/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Interactive circular checklist item matching Apple Notes with animated checkmark scale and hover-revealed delete control.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/core/theme/notes_theme.dart';
import 'package:lusid/features/notes/models/note_model.dart';

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
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(covariant ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text &&
        _controller.text != widget.item.text) {
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
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () => widget.onToggle(!widget.item.isCompleted),
              child: AnimatedScale(
                duration: NotesConstants.microAnimationDuration,
                curve: NotesConstants.defaultAnimationCurve,
                scale: _isPressed ? 0.88 : 1.0,
                child: AnimatedContainer(
                  duration: NotesConstants.microAnimationDuration,
                  curve: NotesConstants.defaultAnimationCurve,
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.item.isCompleted
                        ? NotesTheme.accentGold
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.item.isCompleted
                          ? NotesTheme.accentGold
                          : (_isHovered
                                ? NotesTheme.textSecondary(context)
                                : NotesTheme.textTertiary(context)),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: NotesConstants.microAnimationDuration,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: widget.item.isCompleted
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            key: ValueKey('checked'),
                            size: 11,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(key: ValueKey('unchecked')),
                  ),
                ),
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
            AnimatedOpacity(
              duration: NotesConstants.microAnimationDuration,
              curve: NotesConstants.defaultAnimationCurve,
              opacity: _isHovered ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isHovered,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(20, 20),
                  onPressed: widget.onDelete,
                  child: Icon(
                    CupertinoIcons.clear_circled,
                    size: 15,
                    color: NotesTheme.textTertiary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
