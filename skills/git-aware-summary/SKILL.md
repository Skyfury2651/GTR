---
name: git-aware-summary
description: Keeps a git-tracked project summary (.ai/PROJECT_SUMMARY.md) in sync with the latest commit and uses it as the primary context map for research, planning, and implementation. Runs a pre-flight check at the start of every task, compares the stamped "Last Scanned Commit" with HEAD, rescans only what changed, and re-stamps the summary. Use at the start of any task in a git repository, and when the user mentions project summary, project context, codebase overview, onboarding, architecture, or asks to research, plan, or propose changes.
---

# Git-Aware Project Summary

`.ai/PROJECT_SUMMARY.md` is a compact map of the codebase, stamped with the commit it describes:

```markdown
> Last Scanned Commit: f8e9d0a | Date: 2026-10-28
```

Scripts live next to this file. Resolve `scripts/` relative to this `SKILL.md`, and run them from anywhere inside the target repository.

## Pre-flight (first action of every task)

```
- [ ] 1. Run scripts/check.sh
- [ ] 2. Sync the summary according to status
- [ ] 3. Run scripts/stamp.sh (only if the summary was rewritten)
- [ ] 4. Re-run scripts/check.sh and confirm status=fresh
- [ ] 5. Report one status line, then do the user's task
```

Run:

```bash
sh scripts/check.sh
```

Output is `key=value` lines, followed by `--- commits` and `--- files` sections (`git diff --name-status` format) when the summary is stale.

| `status` | Meaning | Action |
|----------|---------|--------|
| `fresh` | No source changes since the stamped commit | Read the summary and continue |
| `stale` | Commits landed since the last scan | Incremental update |
| `missing` | No summary file | Full scan |
| `unstamped` | Summary has no `Last Scanned Commit` line | Full scan |
| `unreachable` | Stamped commit no longer exists (rebase, force-push, shallow clone) | Full scan |
| `no-git`, `no-commits` | Nothing to track | Skip tracking, read the summary if it exists, continue |

Commits that touch only the summary file are ignored, so committing the summary never makes it stale.

## Incremental update (`status=stale`)

1. Read the current summary.
2. Read the commit list to understand intent, then open the changed files. Prioritise source, schema, config, and route files. Skip lockfiles, generated output, vendored code, and binaries.
3. Edit only the affected sections: modules, integrations, directory map, conventions, commands.
4. Replace `## Recent Changes` with this scan's changes. Each bullet names the file and the behavioural change, not the diff mechanics.
5. If `changed_files` exceeds about 150, `truncated_files` is present, or `ancestor=no` with a large diff, do a full scan instead.

## Full scan (`missing`, `unstamped`, `unreachable`)

1. Copy [template.md](template.md) to the summary path.
2. Explore in this order: README and docs, package manifests, entry points, directory tree (two to three levels), routing and controllers, services and domain logic, data models and migrations, external integrations, config and env usage, tests, CI.
3. Fill every section from evidence in the code. Put unknowns under `## Open Questions` rather than guessing.

## Writing rules

- The summary is a map, not a copy of the code. Keep it under about 300 lines.
- Reference real paths in backticks so later tasks can jump straight to files.
- Never record secrets, tokens, or values from `.env` files. Record config key names only.
- Only committed state is summarised. When `dirty_files` is above 0, inspect uncommitted changes that are relevant to the task, but do not write them into the summary.
- Never run `stamp.sh` without actually updating the content.
- Do not commit the summary unless the user asks.

## Stamp

```bash
sh scripts/stamp.sh
```

This rewrites the `Last Scanned Commit` line with the current HEAD and its commit date, or inserts it under the title when absent. Run `check.sh` again afterwards; it must report `status=fresh`.

## Status line

Tell the user the result in one line before answering:

- `Summary fresh at f8e9d0a.`
- `Summary updated a1b2c3d → f8e9d0a (2 commits, 3 files).`
- `Summary created at f8e9d0a (full scan).`

## Using the summary for the task

1. Use the summary to locate the relevant modules, patterns, and integration points before searching the codebase.
2. Open the referenced files to verify details before proposing or making changes. The summary orients; the code is the source of truth.
3. Ground recommendations in the documented architecture: reuse existing interfaces, follow the recorded conventions, and cite the files involved.
4. If the code contradicts the summary, trust the code, fix the summary, and re-stamp.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `PROJECT_SUMMARY_PATH` | `.ai/PROJECT_SUMMARY.md` | Summary location, relative to the repository root |
| `PROJECT_SUMMARY_MAX_FILES` | `300` | Changed files listed by `check.sh` |
| `PROJECT_SUMMARY_MAX_COMMITS` | `50` | Commits listed by `check.sh` |
