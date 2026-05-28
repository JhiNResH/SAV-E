#!/usr/bin/env bash
set -euo pipefail

team_id="${APPLE_TEAM_ID:-}"
team_id="$(printf '%s' "$team_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:lower:]' '[:upper:]')"

if [[ ! "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "APPLE_TEAM_ID must be a 10-character uppercase alphanumeric Apple Team ID." >&2
  echo "Example: APPLE_TEAM_ID=ABCDE12345 $0" >&2
  exit 2
fi

output_path="${1:-build/ExportOptions.TestFlight.plist}"
mkdir -p "$(dirname "$output_path")"

testflight_scope="${TESTFLIGHT_SCOPE:-external}"
testflight_scope="$(printf '%s' "$testflight_scope" | tr '[:upper:]' '[:lower:]')"
case "$testflight_scope" in
  external)
    internal_only=false
    ;;
  internal)
    internal_only=true
    ;;
  *)
    echo "TESTFLIGHT_SCOPE must be external or internal." >&2
    exit 2
    ;;
esac

cat > "$output_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>upload</string>
  <key>method</key>
  <string>app-store-connect</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${team_id}</string>
  <key>uploadSymbols</key>
  <true/>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>testFlightInternalTestingOnly</key>
  <${internal_only}/>
</dict>
</plist>
PLIST

plutil -lint "$output_path"
echo "$output_path"
