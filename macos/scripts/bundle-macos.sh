#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MACOS_DIR}/.." && pwd)"
DIST_DIR="${MACOS_DIR}/dist"
APP_BUNDLE="${DIST_DIR}/PomoPet.app"

echo "==> Syncing shared/sprites.json..."
cp "${REPO_ROOT}/shared/sprites.json" "${MACOS_DIR}/Sources/PomoPetCore/Resources/sprites.json"

echo "==> Building PomoPet (release)..."
cd "${MACOS_DIR}"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/PomoPet"
BUNDLE_RESOURCE="$(swift build -c release --show-bin-path)/PomoPet_PomoPetCore.bundle"

echo "==> Packaging ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/PomoPet"
cp "${REPO_ROOT}/shared/sprites.json" "${APP_BUNDLE}/Contents/Resources/sprites.json"
if [ -d "${BUNDLE_RESOURCE}" ]; then
  cp -R "${BUNDLE_RESOURCE}" "${APP_BUNDLE}/Contents/Resources/"
fi

cat > "${APP_BUNDLE}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>PomoPet</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomopet.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PomoPet</string>
    <key>CFBundleDisplayName</key>
    <string>PomoPet</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> Done! Launch with: open \"${APP_BUNDLE}\""
