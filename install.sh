#!/usr/bin/env sh
set -eu

name="git-aware-summary"
src="$(cd "$(dirname "$0")" && pwd)"
heading="## Git-Aware Project Summary"
target="."
agent="all"
global=0

usage() {
  cat <<EOF
Usage: install.sh [--agent cursor|claude|all] [--dir PROJECT_DIR] [--global]

  --agent   Agent to install for (default: all)
  --dir     Project directory to install into (default: current directory)
  --global  Install the skill for your user instead of a single project
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --agent) agent="${2:?--agent requires a value}"; shift ;;
    --dir) target="${2:?--dir requires a value}"; shift ;;
    --global) global=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

case "$agent" in
  cursor|claude|all) ;;
  *) echo "error: --agent must be cursor, claude, or all" >&2; exit 1 ;;
esac

if [ "$global" -eq 0 ]; then
  [ -d "$target" ] || { echo "error: $target is not a directory" >&2; exit 1; }
  target="$(cd "$target" && pwd)"
fi

copy_skill() {
  dest="$1/skills/$name"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$src/skills/$name/." "$dest/"
  chmod +x "$dest/scripts/"*.sh
  echo "installed skill -> $dest"
}

append_instructions() {
  file="$1"
  mkdir -p "$(dirname "$file")"
  if [ -f "$file" ] && grep -qF "$heading" "$file"; then
    echo "instructions already present -> $file"
    return
  fi
  cat "$src/templates/agent-instructions.md" >> "$file"
  echo "added instructions -> $file"
}

install_cursor() {
  if [ "$global" -eq 1 ]; then
    copy_skill "$HOME/.cursor"
    echo "note: add the contents of templates/cursor-rule.mdc to Cursor Settings > Rules > User Rules to run it on every prompt"
    return
  fi
  copy_skill "$target/.cursor"
  mkdir -p "$target/.cursor/rules"
  cp "$src/templates/cursor-rule.mdc" "$target/.cursor/rules/$name.mdc"
  echo "installed rule -> $target/.cursor/rules/$name.mdc"
}

install_claude() {
  if [ "$global" -eq 1 ]; then
    copy_skill "$HOME/.claude"
    append_instructions "$HOME/.claude/CLAUDE.md"
    return
  fi
  copy_skill "$target/.claude"
  append_instructions "$target/CLAUDE.md"
}

case "$agent" in
  cursor) install_cursor ;;
  claude) install_claude ;;
  all) install_cursor; install_claude ;;
esac
