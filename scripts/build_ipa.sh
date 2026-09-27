#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "A macOS host with Xcode is required. Run the Build SideStore IPA workflow." >&2
  exit 1
fi
command -v xcodebuild >/dev/null
command -v xcodegen >/dev/null
mkdir -p build
xcodegen generate --spec project.yml
xcodebuild \
  -project Wigy.xcodeproj \
  -scheme Wigy \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  build 2>&1 | tee build/xcodebuild.log

app_path='build/DerivedData/Build/Products/Release-iphoneos/Wigy.app'
test -d "$app_path/PlugIns/WigyWidgets.appex"
rm -rf build/Payload
rm -f build/wigy.ipa
mkdir -p build/Payload
ditto "$app_path" build/Payload/Wigy.app
(
  cd build
  ditto -c -k --keepParent Payload wigy.ipa
)
python3 scripts/validate_ipa.py build/wigy.ipa
echo "Built build/wigy.ipa. SideStore must sign this unsigned IPA before installation."
