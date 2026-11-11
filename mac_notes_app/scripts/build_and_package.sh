#!/usr/bin/env bash
# Author: Domonick Mack
# Date: 2026-11-10
# Description: Automated release build, code-signing, packaging, and SHA-256 checksum script for Lusid (.dmg, .zip, .ipa, Web PWA).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"
RELEASES_DIR="${RELEASES_DIR:-$ROOT_DIR/releases}"

# Resolve release version from environment, git tag, or pubspec.yaml
if [ -n "${RELEASE_VERSION:-}" ]; then
  VERSION="${RELEASE_VERSION#v}"
elif git -C "$ROOT_DIR" describe --tags --exact-match >/dev/null 2>&1; then
  RAW_TAG="$(git -C "$ROOT_DIR" describe --tags --exact-match)"
  VERSION="${RAW_TAG#v}"
else
  PUBSPEC_VER="$(awk '/^version:/ {print $2}' "$APP_DIR/pubspec.yaml" | cut -d'+' -f1)"
  VERSION="${PUBSPEC_VER:-1.0.0}"
fi

VERSION_TAG="v${VERSION}"
SIGN_IDENTITY="${APPLE_DEVELOPER_IDENTITY:--}"
WEB_BASE_HREF="${FLUTTER_WEB_BASE_HREF:-/}"

mkdir -p "$RELEASES_DIR"

echo "========================================================"
echo " Lusid Multi-Platform Release Packager (${VERSION_TAG})"
echo "========================================================"

echo "========================================================"
echo " 1/5 Building Lusid macOS Release Application (.app)..."
echo "========================================================"
cd "$APP_DIR"
flutter build macos --release

MACOS_APP_PATH="$APP_DIR/build/macos/Build/Products/Release/Lusid.app"
if [ ! -d "$MACOS_APP_PATH" ]; then
  # Fallback in case bundle product name is mac_notes_app.app
  ALT_APP_PATH="$APP_DIR/build/macos/Build/Products/Release/mac_notes_app.app"
  if [ -d "$ALT_APP_PATH" ]; then
    MACOS_APP_PATH="$ALT_APP_PATH"
  else
    echo "Error: macOS .app bundle not found at $MACOS_APP_PATH"
    exit 1
  fi
fi

# Sign macOS app bundle (Developer ID if APPLE_DEVELOPER_IDENTITY is set, otherwise ad-hoc '-')
echo "Signing macOS bundle with identity: ${SIGN_IDENTITY}"
codesign --force --deep --sign "$SIGN_IDENTITY" "$MACOS_APP_PATH" || true

echo "========================================================"
echo " 2/5 Packaging Lusid macOS .zip and .dmg Installers..."
echo "========================================================"
ZIP_PATH="$RELEASES_DIR/Lusid-macOS-${VERSION_TAG}.zip"
DMG_PATH="$RELEASES_DIR/Lusid-macOS-${VERSION_TAG}.dmg"
DMG_STAGING="$APP_DIR/build/dmg_staging"

rm -rf "$ZIP_PATH" "$DMG_PATH" "$DMG_STAGING"
ditto -c -k --sequesterRsrc --keepParent "$MACOS_APP_PATH" "$ZIP_PATH"

mkdir -p "$DMG_STAGING"
cp -R "$MACOS_APP_PATH" "$DMG_STAGING/Lusid.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "Lusid Installer" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGING"

# Optional Apple Notarytool notarization when credentials are configured
if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]; then
  echo "Submitting $DMG_PATH to Apple Notary Service..."
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo "========================================================"
echo " 3/5 Building Lusid iPadOS / iOS Release (.ipa)..."
echo "========================================================"
flutter build ios --release --no-codesign

IOS_APP_PATH="$APP_DIR/build/ios/iphoneos/Runner.app"
IPA_STAGING="$APP_DIR/build/ipa_staging"
IPA_PATH="$RELEASES_DIR/Lusid-iPadOS-${VERSION_TAG}.ipa"

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
echo " 4/5 Building Lusid Web / iPadOS PWA Release Bundle..."
echo "========================================================"
flutter build web --release --base-href "$WEB_BASE_HREF"
WEB_ZIP_PATH="$RELEASES_DIR/Lusid-Web-PWA-${VERSION_TAG}.zip"
rm -f "$WEB_ZIP_PATH"
(
  cd "$APP_DIR/build/web"
  zip -r -q "$WEB_ZIP_PATH" .
)

echo "========================================================"
echo " 5/5 Generating & Verifying SHA256SUMS.txt..."
echo "========================================================"
(
  cd "$RELEASES_DIR"
  rm -f SHA256SUMS.txt
  shasum -a 256 ./*.dmg ./*.zip ./*.ipa > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)

echo "========================================================"
echo " Build Complete! Artifacts available in: $RELEASES_DIR"
ls -lh "$RELEASES_DIR"
echo "========================================================"
