import 'package:intl/intl.dart';

/// Utilities for Apple Notes formatting, dates, and text extraction.
class NotesUtils {
  /// Extracts the title from note content:
  /// Apple Notes uses the first non-empty line as the title.
  static String extractTitle(String content, {String defaultTitle = 'New Note'}) {
    final lines = content.trim().split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // Strip markdown headers if any
        return trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
      }
    }
    return defaultTitle;
  }

  /// Extracts the preview snippet from note content:
  /// The subsequent text after the first title line, truncated.
  static String extractSnippet(String content) {
    final lines = content.trim().split('\n');
    if (lines.length <= 1) {
      return 'No additional text';
    }
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        return line.replaceFirst(RegExp(r'^#+\s*'), '');
      }
    }
    return 'No additional text';
  }

  /// Formats relative date for the middle notes list:
  /// - Today: "9:41 AM"
  /// - Yesterday: "Yesterday"
  /// - Within 7 days: Day of week ("Monday")
  /// - This year: "Oct 28"
  /// - Previous years: "10/24/25"
  static String formatListDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);

    final differenceInDays = today.difference(noteDay).inDays;

    if (differenceInDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (differenceInDays == 1) {
      return 'Yesterday';
    } else if (differenceInDays < 7 && differenceInDays > 1) {
      return DateFormat('EEEE').format(date);
    } else if (now.year == date.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('M/d/yy').format(date);
    }
  }

  /// Formats the centered timestamp header in the editor view:
  /// e.g. "November 1, 2026 at 3:30 PM"
  static String formatEditorHeaderDate(DateTime date) {
    return DateFormat("MMMM d, y 'at' h:mm a").format(date);
  }

  /// Categorizes a date into the chronological group names:
  /// - "Today"
  /// - "Previous 7 Days"
  /// - "Previous 30 Days"
  /// - Month Name e.g. "October", "September" or "2025"
  static String getDateGroupName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);
    final daysDiff = today.difference(noteDay).inDays;

    if (daysDiff == 0) {
      return 'Today';
    } else if (daysDiff <= 7) {
      return 'Previous 7 Days';
    } else if (daysDiff <= 30) {
      return 'Previous 30 Days';
    } else if (now.year == date.year) {
      return DateFormat('MMMM').format(date);
    } else {
      return DateFormat('yyyy').format(date);
    }
  }
}
