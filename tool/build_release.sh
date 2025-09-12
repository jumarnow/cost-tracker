#!/usr/bin/env bash
set -euo pipefail

# Build smallest release outputs: AAB and split-per-ABI APKs
# Usage: bash tool/build_release.sh

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found on PATH. Please install/configure Flutter." >&2
  exit 1
fi

echo "==> Cleaning and fetching deps"
flutter clean
flutter pub get

if [[ -f android/key.properties ]]; then
  echo "==> Using release keystore from android/key.properties"
else
  echo "==> No android/key.properties found. Builds will be signed with debug keys (APK) or may require signing later (AAB)."
fi

OUT_DIR="build/debug-info"
mkdir -p "$OUT_DIR"

echo "==> Building App Bundle (AAB) with shrinking + obfuscation"
flutter build appbundle --release \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info="$OUT_DIR"

echo "==> Building split-per-ABI APKs with shrinking + obfuscation"
flutter build apk --release --split-per-abi \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info="$OUT_DIR"

echo "==> Outputs:"
echo " - AAB: build/app/outputs/bundle/release/app-release.aab"
echo " - APKs: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (and others)"

