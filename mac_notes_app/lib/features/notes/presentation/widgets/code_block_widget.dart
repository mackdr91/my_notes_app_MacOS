/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Interactive macOS-style multi-line code block widget featuring fluid copy state transitions, hover elevation, and dynamic line numbers.
 */

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/core/theme/notes_theme.dart';
import 'package:lusid/features/notes/models/note_model.dart';

/// Supported programming languages for code blocks.
class CodeLanguage {
  final String id;
  final String name;

  const CodeLanguage(this.id, this.name);

  static const List<CodeLanguage> supported = [
    CodeLanguage('dart', 'Dart / Flutter'),
    CodeLanguage('python', 'Python / Django'),
    CodeLanguage('javascript', 'JavaScript / TypeScript'),
    CodeLanguage('json', 'JSON'),
    CodeLanguage('sql', 'SQL / Database'),
    CodeLanguage('html', 'HTML / XML'),
    CodeLanguage('css', 'CSS'),
    CodeLanguage('bash', 'Bash / Shell'),
    CodeLanguage('plain', 'Plain Text'),
  ];

  static String getName(String id) {
    final match = supported.firstWhere(
      (l) => l.id.toLowerCase() == id.toLowerCase(),
      orElse: () => CodeLanguage(id, id.toUpperCase()),
    );
    return match.name;
  }
}

/// Interactive macOS-style multi-line code block widget with language selector,
/// line numbers, syntax-aware mono typography, and one-click copy button.
class CodeBlockWidget extends StatefulWidget {
  final NoteCodeBlock codeBlock;
  final ValueChanged<String> onCodeChanged;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onDelete;

  const CodeBlockWidget({
    super.key,
    required this.codeBlock,
    required this.onCodeChanged,
    required this.onLanguageChanged,
    required this.onDelete,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late final TextEditingController _textController;
  bool _isCopied = false;
  bool _isHovered = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.codeBlock.code);
  }

  @override
  void didUpdateWidget(covariant CodeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codeBlock.code != widget.codeBlock.code &&
        _textController.text != widget.codeBlock.code) {
      _textController.text = widget.codeBlock.code;
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (!mounted) return;
    setState(() => _isCopied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  int get _lineCount {
    final text = _textController.text;
    if (text.isEmpty) return 1;
    return text.split('\n').length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final borderColor = _isHovered
        ? (isDark ? const Color(0xFF3E3E44) : const Color(0xFFC7C7CC))
        : NotesTheme.divider(context);
    final headerBg = isDark ? const Color(0xFF141416) : const Color(0xFFF2F2F5);
    final editorBg = isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFC);
    final gutterBg = isDark ? const Color(0xFF0D0D0E) : const Color(0xFFEBEBF0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: NotesConstants.microAnimationDuration,
        curve: NotesConstants.defaultAnimationCurve,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: editorBg,
          border: Border.all(color: borderColor, width: 0.8),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _isHovered ? (isDark ? 0.4 : 0.08) : (isDark ? 0.3 : 0.05),
              ),
              blurRadius: _isHovered ? 8 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. macOS Code Block Header Bar
            AnimatedContainer(
              duration: NotesConstants.microAnimationDuration,
              curve: NotesConstants.defaultAnimationCurve,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7.2)),
                border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: Row(
                children: [
                  // Language Dropdown Badge
                  _LanguageSelectorMenu(
                    currentLanguageId: widget.codeBlock.language,
                    onSelectLanguage: widget.onLanguageChanged,
                  ),

                  const Spacer(),

                  // Copy Button with animated feedback
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    minimumSize: const Size(24, 24),
                    onPressed: _copyCode,
                    child: AnimatedSwitcher(
                      duration: NotesConstants.microAnimationDuration,
                      child: Row(
                        key: ValueKey<bool>(_isCopied),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isCopied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_doc,
                            size: 12.0,
                            color: _isCopied
                                ? const Color(0xFF34C759)
                                : NotesTheme.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isCopied ? 'Copied!' : 'Copy',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _isCopied
                                  ? const Color(0xFF34C759)
                                  : NotesTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Delete Code Block Button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    minimumSize: const Size(24, 24),
                    onPressed: widget.onDelete,
                    child: Icon(
                      CupertinoIcons.trash,
                      size: 12.0,
                      color: CupertinoColors.destructiveRed.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Multi-Line Code Content with Line Number Gutter
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Line Numbers Gutter
                  AnimatedContainer(
                    duration: NotesConstants.microAnimationDuration,
                    curve: NotesConstants.defaultAnimationCurve,
                    width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: gutterBg,
                      border: Border(right: BorderSide(color: borderColor, width: 0.6)),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(7.2)),
                    ),
                    child: Column(
                      children: List.generate(_lineCount, (i) {
                        return SizedBox(
                          height: 20.0,
                          child: Text(
                            '${i + 1}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'SF Mono',
                              fontSize: 11.5,
                              color: NotesTheme.textTertiary(context),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Editable Code Editor Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: CupertinoTextField(
                        controller: _textController,
                        decoration: null,
                        padding: EdgeInsets.zero,
                        maxLines: null,
                        style: TextStyle(
                          fontFamily: 'SF Mono',
                          fontSize: 13.0,
                          height: 20.0 / 13.0,
                          color: NotesTheme.textPrimary(context),
                        ),
                        onChanged: (val) {
                          setState(() {});
                          widget.onCodeChanged(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Popup selector menu for programming languages
class _LanguageSelectorMenu extends StatefulWidget {
  final String currentLanguageId;
  final ValueChanged<String> onSelectLanguage;

  const _LanguageSelectorMenu({
    required this.currentLanguageId,
    required this.onSelectLanguage,
  });

  @override
  State<_LanguageSelectorMenu> createState() => _LanguageSelectorMenuState();
}

class _LanguageSelectorMenuState extends State<_LanguageSelectorMenu> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final displayName = CodeLanguage.getName(widget.currentLanguageId);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapUp: (details) {
          final pos = details.globalPosition;
          showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
            color: isDark ? const Color(0xFF1E1E22) : Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: NotesTheme.divider(context), width: 0.8),
            ),
            items: CodeLanguage.supported.map((lang) {
              final isSelected =
                  lang.id.toLowerCase() == widget.currentLanguageId.toLowerCase();
              return PopupMenuItem<String>(
                value: lang.id,
                height: 32,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(CupertinoIcons.checkmark,
                          size: 12, color: NotesTheme.accentGold)
                    else
                      const SizedBox(width: 12),
                    const SizedBox(width: 8),
                    Text(
                      lang.name,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? NotesTheme.accentGold
                            : NotesTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ).then((selected) {
            if (selected != null) {
              widget.onSelectLanguage(selected);
            }
          });
        },
        child: AnimatedContainer(
          duration: NotesConstants.microAnimationDuration,
          curve: NotesConstants.defaultAnimationCurve,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF323236) : const Color(0xFFDCDCE2))
                : (isDark ? const Color(0xFF252528) : const Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.chevron_left_slash_chevron_right,
                size: 11,
                color: NotesTheme.accentGold,
              ),
              const SizedBox(width: 5),
              Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'SF Mono',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: NotesTheme.textPrimary(context),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                CupertinoIcons.chevron_down,
                size: 9,
                color: NotesTheme.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
