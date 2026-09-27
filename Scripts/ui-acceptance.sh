#!/bin/zsh
set -eu

project_root="${0:A:h:h}"
if (( $# != 1 )); then
  print -u2 "Usage: Scripts/ui-acceptance.sh /path/to/MaterialsIntelligence.app"
  exit 2
fi

source_app="${1:A}"
if [[ ! -d "$source_app" || ! -f "$source_app/Contents/Info.plist" ]]; then
  print -u2 "App bundle not found: $source_app"
  exit 2
fi

temporary_root="$(mktemp -d /tmp/mi-ui-acceptance.XXXXXX)"
app_copy="$temporary_root/MaterialsIntelligence.app"
support_path="$temporary_root/application-support"
bundle_id="com.materialsintelligence.acceptance.$$"
app_pid=""

cleanup() {
  local candidate command_line
  for candidate in ${(f)"$(pgrep -x MaterialsIntelligence || true)"}; do
    command_line="$(ps -p "$candidate" -o command= 2>/dev/null || true)"
    if [[ "$command_line" == *"$temporary_root"* ]]; then
      kill -TERM "$candidate" 2>/dev/null || true
    fi
  done
  rm -rf "$temporary_root"
}
trap cleanup EXIT

ditto "$source_app" "$app_copy"
plutil -replace CFBundleIdentifier -string "$bundle_id" "$app_copy/Contents/Info.plist"
mkdir -p "$support_path"
open -n "$app_copy" --args "--mi-test-application-support=$support_path"

for attempt in {1..60}; do
  for candidate in ${(f)"$(pgrep -x MaterialsIntelligence || true)"}; do
    command_line="$(ps -p "$candidate" -o command= 2>/dev/null || true)"
    if [[ "$command_line" == *"$app_copy"* && "$command_line" == *"$support_path"* ]]; then
      app_pid="$candidate"
    fi
  done
  [[ -n "$app_pid" ]] && break
  sleep 0.25
done

if [[ -z "$app_pid" ]]; then
  print -u2 "The isolated app process did not start."
  exit 1
fi

xcrun swift "$project_root/Scripts/ui-acceptance.swift" "$app_pid" "$app_copy" "$support_path" "$bundle_id"

personal_database="$support_path/personal-public.sqlite"
if [[ ! -f "$personal_database" ]]; then
  print -u2 "FAIL isolated personal vault database was not created"
  exit 1
fi
personal_counts="$(sqlite3 -readonly "$personal_database" "SELECT (SELECT count(*) FROM records)||','||(SELECT count(*) FROM claims)||','||(SELECT count(*) FROM relationships)||','||(SELECT count(*) FROM research_sessions)||','||(SELECT count(*) FROM sync_state);")"
if [[ "$personal_counts" != "0,0,0,0,0" ]]; then
  print -u2 "FAIL tab navigation changed isolated vault data: $personal_counts"
  exit 1
fi
print "PASS navigation left personal vault records, claims, relationships, research, and sync metadata unchanged"
