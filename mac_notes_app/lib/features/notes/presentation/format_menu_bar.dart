import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/theme/notes_theme.dart';

enum NoteTextFormat {
  title,
  heading,
  subheading,
  body,
  monospaced,
  bulletList,
  numberedList,
  bold,
  italic,
  underline,
  strikethrough,
}

/// Floating formatting toolbar matching Apple Notes 'Aa' button with typography and inline styling.
class FormatMenuBar extends StatelessWidget {
  final ValueChanged<NoteTextFormat> onSelectFormat;

  const FormatMenuBar({super.key, required this.onSelectFormat});

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: NotesTheme.divider(context), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inline Style Buttons Row (B, I, U, S)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InlineButton(
                  label: 'B',
                  tooltip: 'Bold (Cmd+B)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  onTap: () => onSelectFormat(NoteTextFormat.bold),
                ),
                _InlineButton(
                  label: 'I',
                  tooltip: 'Italic (Cmd+I)',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13.5),
                  onTap: () => onSelectFormat(NoteTextFormat.italic),
                ),
                _InlineButton(
                  label: 'U',
                  tooltip: 'Underline (Cmd+U)',
                  style: const TextStyle(decoration: TextDecoration.underline, fontSize: 13.5),
                  onTap: () => onSelectFormat(NoteTextFormat.underline),
                ),
                _InlineButton(
                  label: 'S',
                  tooltip: 'Strikethrough',
                  style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 13.5),
                  onTap: () => onSelectFormat(NoteTextFormat.strikethrough),
                ),
              ],
            ),
          ),

          Divider(height: 8, color: NotesTheme.divider(context), thickness: 0.8),

          // Paragraph Styles
          _FormatOption(
            label: 'Title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            onTap: () => onSelectFormat(NoteTextFormat.title),
          ),
          _FormatOption(
            label: 'Heading',
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            onTap: () => onSelectFormat(NoteTextFormat.heading),
          ),
          _FormatOption(
            label: 'Subheading',
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
            onTap: () => onSelectFormat(NoteTextFormat.subheading),
          ),
          _FormatOption(
            label: 'Body',
            style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal),
            onTap: () => onSelectFormat(NoteTextFormat.body),
          ),
          _FormatOption(
            label: 'Monospaced',
            style: const TextStyle(fontSize: 12.5, fontFamily: 'SF Mono'),
            onTap: () => onSelectFormat(NoteTextFormat.monospaced),
          ),

          Divider(height: 8, color: NotesTheme.divider(context), thickness: 0.8),

          // Lists
          _FormatOption(
            label: '• Bulleted List',
            style: const TextStyle(fontSize: 13),
            onTap: () => onSelectFormat(NoteTextFormat.bulletList),
          ),
          _FormatOption(
            label: '1. Numbered List',
            style: const TextStyle(fontSize: 13),
            onTap: () => onSelectFormat(NoteTextFormat.numberedList),
          ),
        ],
      ),
    );
  }
}

class _InlineButton extends StatefulWidget {
  final String label;
  final String tooltip;
  final TextStyle style;
  final VoidCallback onTap;

  const _InlineButton({
    required this.label,
    required this.tooltip,
    required this.style,
    required this.onTap,
  });

  @override
  State<_InlineButton> createState() => _InlineButtonState();
}

class _InlineButtonState extends State<_InlineButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: widget.style.copyWith(
                  color: NotesTheme.textPrimary(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatOption extends StatefulWidget {
  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  State<_FormatOption> createState() => _FormatOptionState();
}

class _FormatOptionState extends State<_FormatOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.5),
          color: _isHovered
              ? (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7))
              : Colors.transparent,
          child: Text(
            widget.label,
            style: widget.style.copyWith(
              color: NotesTheme.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}
