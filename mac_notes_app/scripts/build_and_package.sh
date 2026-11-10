#!/usr/bin/env bash
# Author: Domonick Mack
# Date: 2026-11-09
# Description: Automated release build and packaging script for macOS (.dmg, .zip), iPadOS (.ipa), and Web PWA bundle.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"
RELEASES_DIR="$ROOT_DIR/releases"

mkdir -p "$RELEASES_DIR"

echo "========================================================"
echo " 1/4 Building macOS Release Application (.app)..."
echo "========================================================"
cd "$APP_DIR"
flutter build macos --release

MACOS_APP_PATH="$APP_DIR/build/macos/Build/Products/Release/mac_notes_app.app"
if [ ! -d "$MACOS_APP_PATH" ]; then
  echo "Error: macOS .app bundle not found at $MACOS_APP_PATH"
  exit 1
fi

# Ad-hoc sign the macOS app bundle so it runs cleanly on local and downloaded Macs
codesign --force --deep --sign - "$MACOS_APP_PATH" || true

echo "========================================================"
echo " 2/4 Packaging macOS .zip and .dmg Installers..."
echo "========================================================"
ZIP_PATH="$RELEASES_DIR/Notes-macOS-v1.0.0.zip"
DMG_PATH="$RELEASES_DIR/Notes-macOS-v1.0.0.dmg"
DMG_STAGING="$APP_DIR/build/dmg_staging"

rm -rf "$ZIP_PATH" "$DMG_PATH" "$DMG_STAGING"
ditto -c -k --sequesterRsrc --keepParent "$MACOS_APP_PATH" "$ZIP_PATH"

mkdir -p "$DMG_STAGING"
cp -R "$MACOS_APP_PATH" "$DMG_STAGING/Notes.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "Notes Installer" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"

echo "========================================================"
echo " 3/4 Building iPadOS / iOS Release (.ipa)..."
echo "========================================================"
flutter build ios --release --no-codesign

IOS_APP_PATH="$APP_DIR/build/ios/iphoneos/Runner.app"
IPA_STAGING="$APP_DIR/build/ipa_staging"
IPA_PATH="$RELEASES_DIR/Notes-iPadOS-v1.0.0.ipa"

if [ -d "$IOS_APP_PATH" ]; then
  rm -rf "$IPA_STAGING" "$IPA_PATH"
  mkdir -p "$IPA_STAGING/Payload"
  cp -R "$IOS_APP_PATH" "$IPA_STAGING/Payload/Runner.app"
  (
    cd "$IPA_STAGING"
    zip -r -q "$IPA_PATH" Payload
  )
  rm -rf "$IPA_STAGING"
fi

echo "========================================================"
echo " 4/4 Building Web / iPadOS PWA Release Bundle..."
echo "========================================================"
flutter build web --release
WEB_ZIP_PATH="$RELEASES_DIR/Notes-Web-PWA-v1.0.0.zip"
rm -f "$WEB_ZIP_PATH"
(
  cd "$APP_DIR/build/web"
  zip -r -q "$WEB_ZIP_PATH" .
)

echo "========================================================"
echo " Build Complete! Artifacts available in: $RELEASES_DIR"
ls -lh "$RELEASES_DIR"
echo "========================================================"
