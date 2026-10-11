#!/bin/bash
# Usage: ./publish.sh /path/Overcast.ipa
set -e
IPA="$1"; cd "$(dirname "$0")"
TAG="build-$(date +%Y%m%d-%H%M)"
gh release create "$TAG" "$IPA#Overcast.ipa" --repo DuckyMcGucky/overcast-builds --title "Overcast $TAG" --notes "Ad hoc build" >/dev/null
URL="https://github.com/DuckyMcGucky/overcast-builds/releases/download/$TAG/Overcast.ipa"
cat > manifest.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>items</key><array><dict>
<key>assets</key><array><dict><key>kind</key><string>software-package</string><key>url</key><string>$URL</string></dict></array>
<key>metadata</key><dict><key>bundle-identifier</key><string>Ducky.Overcast</string><key>bundle-version</key><string>1.0</string><key>kind</key><string>software</string><key>title</key><string>Overcast</string></dict>
</dict></array></dict></plist>
P
sed -i "s/Build: .*</Build: $TAG</" index.html
git add -A && git commit -qm "$TAG" && git push -q origin main
echo "$TAG"
