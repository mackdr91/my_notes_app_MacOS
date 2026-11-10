/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: System constants, layout constraints, and fluid animation timing definitions for the Apple Notes macOS replica.
 */

import 'package:flutter/animation.dart';

/// System constants for the Apple Notes macOS replica.
class NotesConstants {
  // Folder IDs
  static const String allNotesFolderId = 'all_notes';
  static const String quickNotesFolderId = 'quick_notes';
  static const String trashFolderId = 'trash';
  static const String defaultNotesFolderId = 'notes';

  // Accounts
  static const String accountICloud = 'iCloud';
  static const String accountOnMyMac = 'On My Mac';

  // Storage Keys
  static const String notesStorageKey = 'apple_notes_data_v1';
  static const String foldersStorageKey = 'apple_folders_data_v1';
  static const String tagsStorageKey = 'apple_tags_data_v1';
  static const String activeFolderKey = 'apple_active_folder_id';

  // Layout Constraints
  static const double minSidebarWidth = 190.0;
  static const double maxSidebarWidth = 300.0;
  static const double defaultSidebarWidth = 220.0;

  static const double minListWidth = 240.0;
  static const double maxListWidth = 400.0;
  static const double defaultListWidth = 290.0;

  static const double minEditorWidth = 450.0;
  static const double toolbarHeight = 52.0;

  // Window titlebar traffic light inset
  static const double trafficLightInsetLeft = 80.0;

  // Fluid Animation Timings & Curves
  static const Duration microAnimationDuration = Duration(milliseconds: 150);
  static const Duration contentAnimationDuration = Duration(milliseconds: 220);
  static const Duration layoutAnimationDuration = Duration(milliseconds: 250);
  static const Duration themeAnimationDuration = Duration(milliseconds: 240);

  static const Curve defaultAnimationCurve = Curves.easeOutCubic;
  static const Curve exitAnimationCurve = Curves.easeInCubic;
  static const Curve layoutAnimationCurve = Curves.fastOutSlowIn;
}
