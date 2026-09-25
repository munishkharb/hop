#!/usr/bin/env bash
# Build Hop.app and a .dmg that contains it, ready to attach to a release.
#
#   scripts/package.sh [version]     e.g. scripts/package.sh 1.1.0
#
# Output lands in dist/: Hop.app, Hop-<version>.dmg and Hop-<version>.zip.
# The binary is universal (Apple silicon and Intel). The app is ad-hoc
# signed, which is enough to run locally; a downloaded copy is still
# quarantined by Gatekeeper until it is signed with a Developer ID and
# notarized (see README, "Install").
set -euo pipefail

cd "$(dirname "$0")/.."
version="${1:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Sources/Hop/Info.plist)}"
version="${version#v}"

swift build -c release --arch arm64 --arch x86_64
bin="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Hop"

rm -rf dist
app="dist/Hop.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/Hop"
cp Sources/Hop/Info.plist "$app/Contents/Info.plist"
cp Sources/Hop/Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$app/Contents/PkgInfo"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $version" "$app/Contents/Info.plist"

codesign --force --sign - "$app"
codesign --verify --strict "$app"

# The dmg holds the app next to an Applications link, so installing is one drag.
staging="$(mktemp -d)"
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "Hop $version" -srcfolder "$staging" -ov -format UDZO "dist/Hop-$version.dmg" >/dev/null
rm -rf "$staging"

ditto -c -k --keepParent "$app" "dist/Hop-$version.zip"

(cd dist && shasum -a 256 "Hop-$version.dmg" "Hop-$version.zip" > SHA256SUMS)
echo "Built dist/Hop-$version.dmg and dist/Hop-$version.zip"
