#!/usr/bin/env bash
set -o pipefail

timestamp="$(date +%Y%m%d-%H%M%S)"
log_path="${SAVE_XCODEBUILD_LOG:-/tmp/save-xcodebuild-${timestamp}.log}"

xcodebuild "$@" 2>&1 \
  | tee "$log_path" \
  | awk '
      /DTDKRemoteDeviceConnection: Failed to start remote service "com\.apple\.mobile\.notification_proxy"/ {
        suppress = 1
        next
      }
      suppress {
        if (/NSLocalizedDescription=Failed to start remote service "com\.apple\.mobile\.notification_proxy"/) {
          suppress = 0
        }
        next
      }
      { print }
    '

status=${PIPESTATUS[0]}
echo "Full xcodebuild log: ${log_path}" >&2
exit "$status"
