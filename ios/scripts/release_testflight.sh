#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$ROOT/ios/Caltrack.xcodeproj"
SCHEME="Caltrack"
APP_ICON="$ROOT/ios/Caltrack/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
BUILD_NUMBER="${1:-}"
ACTION="${2:-archive}"

if [[ -z "$BUILD_NUMBER" || ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Uso: ios/scripts/release_testflight.sh BUILD [archive|upload]" >&2
  exit 2
fi
if [[ "$ACTION" != "archive" && "$ACTION" != "upload" ]]; then
  echo "La acción debe ser archive o upload." >&2
  exit 2
fi
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
  echo "El repositorio debe estar limpio para crear una release reproducible." >&2
  exit 1
fi

for name in ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID; do
  if [[ -z "${!name:-}" ]]; then
    echo "Falta $name en el entorno." >&2
    exit 1
  fi
done
if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "ASC_KEY_PATH no apunta a un archivo existente." >&2
  exit 1
fi
if [[ ! -f "$APP_ICON" ]]; then
  echo "Falta el icono principal de App Store." >&2
  exit 1
fi
ICON_ALPHA="$(sips -g hasAlpha "$APP_ICON" 2>/dev/null | awk '/hasAlpha:/{print $2}')"
if [[ "$ICON_ALPHA" != "no" ]]; then
  echo "El icono principal contiene transparencia y App Store Connect lo rechazará." >&2
  exit 1
fi

SETTINGS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release -showBuildSettings 2>/dev/null)"
PROJECT_BUILD="$(awk '/CURRENT_PROJECT_VERSION =/{print $3; exit}' <<<"$SETTINGS")"
VERSION="$(awk '/MARKETING_VERSION =/{print $3; exit}' <<<"$SETTINGS")"
if [[ "$PROJECT_BUILD" != "$BUILD_NUMBER" ]]; then
  echo "La build solicitada es $BUILD_NUMBER, pero el proyecto declara $PROJECT_BUILD." >&2
  exit 1
fi

OUTPUT="$ROOT/build/release-$BUILD_NUMBER"
ARCHIVE="$OUTPUT/Caltrack.xcarchive"
EXPORT="$OUTPUT/export"
LOGS="$OUTPUT/logs"
rm -rf "$OUTPUT"
mkdir -p "$EXPORT" "$LOGS"

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  | tee "$LOGS/archive.log"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$ROOT/ios/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  | tee "$LOGS/export.log"

IPA="$(find "$EXPORT" -maxdepth 1 -type f -name '*.ipa' -print -quit)"
if [[ -z "$IPA" ]]; then
  echo "La exportación no produjo un IPA." >&2
  exit 1
fi

IPA_SHA256="$(shasum -a 256 "$IPA" | awk '{print $1}')"
{
  echo "commit=$(git -C "$ROOT" rev-parse HEAD)"
  echo "version=$VERSION"
  echo "build=$BUILD_NUMBER"
  echo "ipa_sha256=$IPA_SHA256"
} > "$OUTPUT/manifest.txt"

if [[ "$ACTION" == "upload" ]]; then
  xcrun altool --validate-app \
    -f "$IPA" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" \
    | tee "$LOGS/validate.log"
  xcrun altool --upload-app \
    -f "$IPA" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" \
    | tee "$LOGS/upload.log"
fi

echo "Release preparada: $IPA"
echo "Manifest: $OUTPUT/manifest.txt"
