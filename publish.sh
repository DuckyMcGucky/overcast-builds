#!/bin/bash
# Usage: ./publish.sh /path/Overcast.ipa <version e.g. 0.1> <notes-file (markdown changelog section)>
# Channel defaults to Alpha; override with CHANNEL=Beta ./publish.sh ...
set -e
IPA="$1"; VER="$2"; NOTES="$3"
[ -f "$IPA" ] && [ -n "$VER" ] && [ -f "$NOTES" ] || { echo "usage: $0 <ipa> <version> <notes-file>"; exit 1; }
NOTES="$(cd "$(dirname "$NOTES")" && pwd)/$(basename "$NOTES")"
cd "$(dirname "$0")"
CHANNEL="${CHANNEL:-Alpha}"; LC=$(echo "$CHANNEL" | tr A-Z a-z)
TAG="$LC-$VER"; LABEL="$CHANNEL $VER"
cp "$IPA" /tmp/Overcast.ipa
gh release create "$TAG" /tmp/Overcast.ipa --repo DuckyMcGucky/overcast-builds --title "Overcast $LABEL" --notes-file "$NOTES" >/dev/null
URL="https://github.com/DuckyMcGucky/overcast-builds/releases/download/$TAG/Overcast.ipa"
cat > manifest.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>items</key><array><dict>
<key>assets</key><array><dict><key>kind</key><string>software-package</string><key>url</key><string>$URL</string></dict></array>
<key>metadata</key><dict><key>bundle-identifier</key><string>Ducky.Overcast</string><key>bundle-version</key><string>$VER</string><key>kind</key><string>software</string><key>title</key><string>Overcast $LABEL</string></dict>
</dict></array></dict></plist>
P
NOTES_HTML=$(python3 - "$NOTES" <<'PY'
import sys,html
out=[];inl=False
for l in open(sys.argv[1]).read().splitlines():
    l=l.rstrip()
    if l.startswith('- '):
        if not inl: out.append('<ul>'); inl=True
        out.append('<li>'+html.escape(l[2:])+'</li>')
    else:
        if inl: out.append('</ul>'); inl=False
        if l.startswith('#'): out.append('<h3>'+html.escape(l.lstrip('# '))+'</h3>')
        elif l: out.append('<p>'+html.escape(l)+'</p>')
if inl: out.append('</ul>')
print('\n'.join(out))
PY
)
cat > index.html <<H
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Overcast $LABEL</title>
<style>body{font-family:-apple-system,sans-serif;display:flex;flex-direction:column;align-items:center;margin:0;padding:40px 20px}a{background:#0a84ff;color:#fff;padding:16px 32px;border-radius:12px;text-decoration:none;font-size:20px;font-weight:600}.v{color:#888}.notes{max-width:640px;text-align:left;margin-top:32px;line-height:1.45}</style></head>
<body><h1>Overcast</h1><a href="itms-services://?action=download-manifest&url=https://duckymcgucky.github.io/overcast-builds/manifest.plist">Install</a><p class="v">Version: $LABEL</p>
<div class="notes">
$NOTES_HTML
</div></body></html>
H
git add -A && git commit -qm "$TAG" && git push -q origin main
echo "$TAG"
