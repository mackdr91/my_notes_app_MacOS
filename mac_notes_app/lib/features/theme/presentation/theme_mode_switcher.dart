/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Segmented toolbar control for switching between System, Light, and Dark mode with smooth animated selection pills.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/core/theme/notes_theme.dart';
import 'package:lusid/features/theme/providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Segmented toolbar control for switching between System, Light, and Dark mode.
class ThemeModeSwitcher extends StatelessWidget {
  const ThemeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);
    final currentMode = context.select<ThemeProvider, ThemeMode>(
      (p) => p.themeMode,
    );

    return AnimatedContainer(
      duration: NotesConstants.themeAnimationDuration,
      curve: NotesConstants.defaultAnimationCurve,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26262A) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isDark ? const Color(0xFF333338) : const Color(0xFFD1D1D6),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Auto (Follow System Appearance)
          _ThemeSegmentButton(
            icon: CupertinoIcons.circle_lefthalf_fill,
            tooltip: 'Auto: Follow macOS System Appearance',
            isSelected: currentMode == ThemeMode.system,
            onPressed: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.system);
            },
          ),

          // 2. Light Mode
          _ThemeSegmentButton(
            icon: CupertinoIcons.sun_max,
            tooltip: 'Light Mode (Ultra-Crisp White)',
            isSelected: currentMode == ThemeMode.light,
            onPressed: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
            },
          ),

          // 3. Dark Mode
          _ThemeSegmentButton(
            icon: CupertinoIcons.moon_fill,
            tooltip: 'Dark Mode (High Contrast Pure Black)',
            isSelected: currentMode == ThemeMode.dark,
            onPressed: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeSegmentButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ThemeSegmentButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_ThemeSegmentButton> createState() => _ThemeSegmentButtonState();
}

class _ThemeSegmentButtonState extends State<_ThemeSegmentButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    Color bg = Colors.transparent;
    if (widget.isSelected) {
      bg = isDark ? const Color(0xFF3A3A3E) : Colors.white;
    } else if (_isHovered) {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04);
    }

    final Color iconColor = widget.isSelected
        ? NotesTheme.accentGold
        : NotesTheme.textSecondary(context);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            duration: NotesConstants.microAnimationDuration,
            curve: NotesConstants.defaultAnimationCurve,
            scale: _isPressed ? 0.92 : 1.0,
            child: AnimatedContainer(
              duration: NotesConstants.microAnimationDuration,
              curve: NotesConstants.defaultAnimationCurve,
              width: 26,
              height: 24,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4.5),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.4 : 0.12,
                          ),
                          blurRadius: 1.5,
                          offset: const Offset(0, 0.5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(widget.icon, size: 13.5, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
