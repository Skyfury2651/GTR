# git-aware-summary

An agent skill that keeps a living project summary in sync with git, and makes the agent read it before every task.

At the start of every prompt the agent:

1. Compares the commit stamped in `.ai/PROJECT_SUMMARY.md` with `HEAD`.
2. Rescans only the files changed since that commit, or does a full scan if there is no summary yet.
3. Re-stamps the summary with the new commit hash and date.
4. Uses the refreshed summary as its map for research, planning, and implementation.

Works with Cursor, Claude Code, and any agent that supports the [Agent Skills](https://agentskills.io) format.

## Why

Agents waste the first part of every session rediscovering the codebase, or worse, work from stale notes. Static context files (`CLAUDE.md`, `.cursorrules`, Memory Bank, `/init` output) drift silently as the code changes. This skill ties the summary to a commit hash, so staleness is detected mechanically and fixed incrementally.

| Approach | Tracks freshness | Incremental | Summarised for agents |
|----------|------------------|-------------|------------------------|
| `CLAUDE.md` / `/init` | No | No | Yes |
| Repomix | No | No | No (full dump) |
| OpenSpec | Per change proposal | Yes | Specs, not architecture |
| **git-aware-summary** | Commit hash | Yes (git diff) | Yes |

## Install

### With the skills CLI

```bash
npx skills add Skyfury2651/GTR
```

### With the installer

```bash
git clone https://github.com/Skyfury2651/GTR.git
cd GTR

./install.sh --dir /path/to/your/project
./install.sh --dir /path/to/your/project --agent cursor
./install.sh --dir /path/to/your/project --agent claude
./install.sh --global
```

| Agent | Skill location | Always-on trigger |
|-------|----------------|-------------------|
| Cursor | `.cursor/skills/git-aware-summary/` | `.cursor/rules/git-aware-summary.mdc` (`alwaysApply: true`) |
| Claude Code | `.claude/skills/git-aware-summary/` | Section appended to `CLAUDE.md` |

A skill alone only loads when the agent thinks it is relevant. The always-on trigger is what makes the pre-flight run on every prompt. For a global Cursor install, paste `templates/cursor-rule.mdc` into **Cursor Settings → Rules → User Rules**.

### Manually

Copy `skills/git-aware-summary/` into your agent's skills directory, then add `templates/agent-instructions.md` to your always-loaded instructions file (`AGENTS.md`, `CLAUDE.md`, or a Cursor rule).

## How it works

The summary carries a stamp under its title:

```markdown
# Project Architecture & State Summary
> Last Scanned Commit: f8e9d0a | Date: 2026-10-28
```

`scripts/check.sh` prints a machine-readable status:

```text
status=stale
summary=.ai/PROJECT_SUMMARY.md
head=f8e9d0a
head_date=2026-10-28
dirty_files=0
scanned=a1b2c3d
scanned_date=2026-10-25
ancestor=yes
commits_behind=2
changed_files=2
--- commits
f8e9d0a 2026-10-28 Add Stripe webhook handler
7c41b2e 2026-10-27 Add Stripe service
--- files
M	src/controllers/payment.controller.ts
A	src/services/stripe.service.ts
```

| Status | Agent action |
|--------|--------------|
| `fresh` | Read the summary and continue |
| `stale` | Update affected sections from the diff, rewrite Recent Changes |
| `missing` / `unstamped` | Full scan using `template.md` |
| `unreachable` | Full scan (stamped commit was rebased away or the clone is shallow) |
| `no-git` / `no-commits` | Skip tracking |

`scripts/stamp.sh` writes the current `HEAD` into the stamp line. Commits that change only the summary file are ignored, so you can commit `.ai/PROJECT_SUMMARY.md` without making it stale.

## Example session

> **User:** Research and propose how to add MoMo wallet to the payment system.

> **Agent:** Summary updated a1b2c3d → f8e9d0a (2 commits, 2 files).
>
> The payment flow uses a strategy pattern in `src/controllers/payment.controller.ts`, with Stripe implemented in `src/services/stripe.service.ts`. To add MoMo:
>
> 1. Create `src/services/momo.service.ts` implementing the same payment provider interface as `stripe.service.ts`.
> 2. Register the MoMo strategy in `payment.controller.ts`.
> 3. Add an IPN route next to the Stripe webhook route, verifying the MoMo HMAC-SHA256 signature.
> 4. Add `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY` to the config schema.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `PROJECT_SUMMARY_PATH` | `.ai/PROJECT_SUMMARY.md` | Summary location, relative to the repository root |
| `PROJECT_SUMMARY_MAX_FILES` | `300` | Changed files listed by `check.sh` |
| `PROJECT_SUMMARY_MAX_COMMITS` | `50` | Commits listed by `check.sh` |

## Requirements

- `git`
- A POSIX shell (`sh`, `bash`, `dash`, `zsh`). On Windows, use Git Bash or WSL.

## Repository layout

```text
skills/git-aware-summary/
├── SKILL.md
├── template.md
└── scripts/
    ├── check.sh
    └── stamp.sh
templates/
├── cursor-rule.mdc
└── agent-instructions.md
install.sh
```

## License

[MIT](LICENSE)
