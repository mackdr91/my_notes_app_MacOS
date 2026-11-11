/*
 * Author: Domonick Mack
 * Date: 2026-11-10
 * Description: Native macOS About dialog and reusable AppIconBadge widget showcasing the Lusid Dark/Amber emblem.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lusid/core/constants/notes_constants.dart';
import 'package:lusid/core/theme/notes_theme.dart';

/// Reusable widget that renders the bundled Minimalist Dark/Amber macOS app icon
/// with a resilient vector fallback if asset loading is unavailable.
class AppIconBadge extends StatelessWidget {
  final double size;

  const AppIconBadge({super.key, this.size = 64.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        NotesConstants.appIconAssetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF26262E), Color(0xFF101015)],
              ),
              borderRadius: BorderRadius.circular(size * 0.225),
              border: Border.all(
                color: NotesTheme.accentGold.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.square_pencil,
                size: size * 0.52,
                color: NotesTheme.accentGold,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Native macOS About window modal displaying the Lusid app icon, version, and build details.
class AboutLusidDialog extends StatelessWidget {
  const AboutLusidDialog({super.key});

  /// Displays the About Lusid modal with a smooth scale & fade entrance.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss About Lusid',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: NotesConstants.contentAnimationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Center(child: AboutLusidDialog());
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: NotesConstants.defaultAnimationCurve,
          reverseCurve: NotesConstants.exitAnimationCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = NotesTheme.isDark(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1F) : const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isDark
                ? NotesTheme.accentGold.withValues(alpha: 0.25)
                : NotesTheme.divider(context),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconBadge(size: 88.0),
            const SizedBox(height: 12),
            Text(
              NotesConstants.appName,
              style: TextStyle(
                fontFamily: '.AppleSystemUIFont',
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: NotesTheme.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NotesConstants.appVersion,
              style: TextStyle(
                fontFamily: '.AppleSystemUIFont',
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: NotesTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lusid for macOS, iPadOS & Web — Rich Text, Live Markdown, Checklists, Tables, Code Blocks & Cloud Sync.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: '.AppleSystemUIFont',
                fontSize: 12.0,
                height: 1.4,
                color: NotesTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              NotesConstants.appCopyright,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: '.AppleSystemUIFont',
                fontSize: 10.5,
                color: NotesTheme.textTertiary(context),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 7.0),
                minimumSize: const Size(0, 30),
                color: NotesTheme.accentGold,
                borderRadius: BorderRadius.circular(7.0),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: '.AppleSystemUIFont',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
