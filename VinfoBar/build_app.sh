#!/bin/bash
set -e

APP_NAME="VinfoBar"
BUNDLE_ID="com.vinfo.bar"
VERSION="1.0.0"

# Build
echo "Building..."
swift build -c release

# Create .app bundle
APP_DIR="build/${APP_NAME}.app"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy executable
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "Info.plist" "${APP_DIR}/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "${APP_DIR}/Contents/PkgInfo"

# Copy assets (if exists)
if [ -f "Assets/AppIcon.icns" ]; then
    cp "Assets/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo "Created ${APP_DIR}"

# Optional: Code sign
# codesign --force --deep --sign - "${APP_DIR}"