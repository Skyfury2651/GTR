#!/usr/bin/env sh
set -eu

summary="${PROJECT_SUMMARY_PATH:-.ai/PROJECT_SUMMARY.md}"
max_files="${PROJECT_SUMMARY_MAX_FILES:-300}"
max_commits="${PROJECT_SUMMARY_MAX_COMMITS:-50}"

field() {
  printf '%s=%s\n' "$1" "$2"
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  field status no-git
  exit 0
fi

cd "$(git rev-parse --show-toplevel)"

if ! git rev-parse --verify -q HEAD >/dev/null; then
  field status no-commits
  field summary "$summary"
  exit 0
fi

head="$(git rev-parse --short HEAD)"
head_date="$(git log -1 --date=short --format=%cd HEAD)"
dirty="$(git status --porcelain -- . ":(exclude)$summary" | wc -l | tr -d ' ')"

context() {
  field summary "$summary"
  field head "$head"
  field head_date "$head_date"
  field dirty_files "$dirty"
}

if [ ! -f "$summary" ]; then
  field status missing
  context
  exit 0
fi

scanned="$(sed -n 's/^> Last Scanned Commit: *\([0-9a-fA-F]\{4,40\}\).*/\1/p' "$summary" | head -n 1)"
scanned_date="$(sed -n 's/^> Last Scanned Commit:.*| *Date: *\([0-9-]*\).*/\1/p' "$summary" | head -n 1)"

if [ -z "$scanned" ]; then
  field status unstamped
  context
  exit 0
fi

if ! git rev-parse --verify -q "$scanned^{commit}" >/dev/null; then
  field status unreachable
  context
  field scanned "$scanned"
  field scanned_date "$scanned_date"
  exit 0
fi

changes="$(git diff --name-status "$scanned" HEAD -- . ":(exclude)$summary")"

if [ -z "$changes" ]; then
  field status fresh
  context
  field scanned "$scanned"
  field scanned_date "$scanned_date"
  exit 0
fi

total="$(printf '%s\n' "$changes" | wc -l | tr -d ' ')"
ancestor=no
if git merge-base --is-ancestor "$scanned" HEAD; then
  ancestor=yes
fi

field status stale
context
field scanned "$scanned"
field scanned_date "$scanned_date"
field ancestor "$ancestor"
field commits_behind "$(git rev-list --count "$scanned..HEAD" -- . ":(exclude)$summary")"
field changed_files "$total"
if [ "$total" -gt "$max_files" ]; then
  field truncated_files "$((total - max_files))"
fi

echo "--- commits"
git log --date=short --format='%h %cd %s' "$scanned..HEAD" -- . ":(exclude)$summary" | head -n "$max_commits"
echo "--- files"
printf '%s\n' "$changes" | head -n "$max_files"
