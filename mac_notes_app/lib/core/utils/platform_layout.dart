/*
 * Author: Domonick Mack
 * Date: 2026-11-09
 * Description: Platform detection and responsive viewport breakpoint utilities for macOS and iPadOS layouts.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mac_notes_app/core/constants/notes_constants.dart';

/// Responsive size classes for macOS desktop and iPadOS multitasking viewports.
enum ScreenSizeClass {
  /// Full 3-column layout (Mac desktop & iPad Landscape >= 960pt).
  wide,

  /// 2-column master-detail layout with slide-over sidebar drawer (iPad Portrait / Split View 680pt..959pt).
  medium,

  /// Single-column drill-down layout with slide-over sidebar drawer (iPad Slide Over / Compact < 680pt).
  compact,
}

/// Helper providing platform-aware insets, touch target sizing, and responsive breakpoints.
class PlatformLayout {
  static const double wideBreakpoint = 960.0;
  static const double mediumBreakpoint = 680.0;

  /// Returns true when running as a native macOS desktop app (not iPadOS or Web).
  static bool isMacOSDesktop(BuildContext context) {
    if (kIsWeb) return false;
    return Theme.of(context).platform == TargetPlatform.macOS;
  }

  /// Returns true when running on a touch-primary platform (iPadOS / iOS / Android).
  static bool isTouchDevice(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Determines the responsive [ScreenSizeClass] for a given viewport width.
  static ScreenSizeClass sizeClassForWidth(double width) {
    if (width >= wideBreakpoint) {
      return ScreenSizeClass.wide;
    } else if (width >= mediumBreakpoint) {
      return ScreenSizeClass.medium;
    } else {
      return ScreenSizeClass.compact;
    }
  }

  /// Left inset for the unified toolbar: reserves 80pt for macOS traffic lights on native macOS,
  /// and uses a clean 16pt inset on iPadOS and Web.
  static double toolbarLeftInset(BuildContext context) {
    return isMacOSDesktop(context) ? NotesConstants.trafficLightInsetLeft : 16.0;
  }

  /// Toolbar height: 56pt on touch devices (iPadOS) and 52pt on macOS desktop.
  static double toolbarHeight(BuildContext context) {
    return isTouchDevice(context) ? 56.0 : NotesConstants.toolbarHeight;
  }

  /// Toolbar button hit target dimension: 36pt on touch devices and 30pt on macOS desktop.
  static double toolbarButtonSize(BuildContext context) {
    return isTouchDevice(context) ? 36.0 : 30.0;
  }
}
