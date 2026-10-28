#!/usr/bin/env sh
set -eu

summary="${PROJECT_SUMMARY_PATH:-.ai/PROJECT_SUMMARY.md}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 1
fi

cd "$(git rev-parse --show-toplevel)"

if ! git rev-parse --verify -q HEAD >/dev/null; then
  echo "error: repository has no commits yet" >&2
  exit 1
fi

if [ ! -f "$summary" ]; then
  echo "error: $summary not found, write the summary before stamping" >&2
  exit 1
fi

head="$(git rev-parse --short HEAD)"
date="$(git log -1 --date=short --format=%cd HEAD)"
line="> Last Scanned Commit: $head | Date: $date"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if grep -q '^> Last Scanned Commit:' "$summary"; then
  awk -v line="$line" '!done && /^> Last Scanned Commit:/ { print line; done = 1; next } { print }' "$summary" > "$tmp"
else
  awk -v line="$line" '
    NR == 1 && /^# / { print; print line; next }
    NR == 1 { print line; print "" }
    { print }
  ' "$summary" > "$tmp"
fi

cat "$tmp" > "$summary"
echo "stamped $summary at $head ($date)"
