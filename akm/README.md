# AKM — Agent Kit Manager

A CLI tool for managing reusable [Agent Skills](https://agentskills.io/), LLM session artifacts, and global instructions across LLM-powered coding assistants (Claude Code, GitHub Copilot CLI, OpenCode, and more).

## Features

- **Skills management** — Cold library, three-layer activation (core/project/session), per-session isolation
- **Artifact sync** — Auto-sync LLM session outputs (plans, research, notes) to a git repo
- **Global instructions** — Distribute shared LLM instructions to all tool directories
- **Multi-tool support** — Works with Claude Code, GitHub Copilot CLI, OpenCode, and more
- **60+ skills included** — Development workflows, code review, TDD, planning, debugging, and more

## Prerequisites

- **jq** — Install with your package manager (e.g., `sudo apt-get install jq`, `brew install jq`)
- **git** — For cloning, repo detection, and artifact sync

## Quick Start

```bash
# Clone and install
git clone https://github.com/<org>/akm ~/akm
bash ~/akm/install.sh

# Configure (interactive)
akm setup

# Open a new terminal (or source ~/.bashrc), then:
akm skills status
```

## How It Works

### Three Domains

AKM manages three independent subsystems, each enableable via `akm setup`:

| Domain | Purpose | Key command |
|--------|---------|-------------|
| **Skills** | Manage and load LLM skills/agents | `akm skills sync` |
| **Artifacts** | Sync session outputs to a git repo | `akm artifacts sync` |
| **Instructions** | Distribute global LLM instructions | `akm instructions sync` |

### Skills: Three-Layer Activation

```
Layer 1 — Core (global, always available)
  akm skills sync → cold library (~/.local/share/akm/)
                   → symlinks into ~/.claude/, ~/.copilot/, ~/.agents/

Layer 2 — Project (declared in manifest, loaded at session start)
  .agents/akm.json lists skill/agent IDs
  → shell wrapper reads manifest → symlinks into staging dir

Layer 3 — Session (JIT, mid-session)
  akm skills load <id>   → adds to active staging dir
  akm skills unload <id> → removes from staging dir
```

### Shell Wrappers

When you source `akm-init.sh` (wired by `akm setup`), wrapper functions for `claude`, `copilot`, and `opencode` automatically:
1. Pull latest artifacts (if enabled)
2. Create a per-session skills staging directory (if enabled)
3. Pass relevant dirs to the tool via `--add-dir`
4. Commit and push artifacts on exit (if auto-push enabled)
5. Clean up staging directory on exit

## CLI Reference

```
akm <command> [subcommand] [options]

Setup & Config:
  setup                          Interactive feature configuration
    --skills                     Configure skills only
    --artifacts                  Configure artifacts only
    --instructions               Configure instructions only
  config <key> [value]           Get or set a config value
  sync                           Sync all enabled subsystems
  help                           Show help

Skills:
  skills sync                    Pull remote → cold library → rebuild symlinks
  skills add <id> [id...]        Add spec ID(s) to project manifest
  skills remove <id> [id...]     Remove spec ID(s) from project manifest
  skills load <id> [id...]       Load spec into active session (JIT)
  skills unload <id> [id...]     Remove spec from active session
  skills loaded                  Show specs in active session
  skills list [--tag TAG] [--type TYPE]  List library
  skills search <query>          Search library by keyword
  skills status                  Show core, session, manifest, and cold specs
  skills clean [--project]       Remove stale specs
  skills publish <id>            Publish local spec to source repo as PR
  skills libgen                  Regenerate library.json from disk

Artifacts:
  artifacts sync                 Bidirectional sync with artifacts remote

Instructions:
  instructions sync              Distribute global instructions to tool dirs
  instructions scaffold-project  Create AGENTS.md + CLAUDE.md in project root
```

## Configuration

All config lives in `~/.config/akm/config` (flat key=value, sourceable by bash):

```bash
FEATURES="skills,artifacts,instructions"
SKILLS_REMOTE="git@github.com:user/skills-library.git"
ARTIFACTS_REMOTE="git@github.com:user/llm-artifacts.git"
ARTIFACTS_DIR="$HOME/.akm/artifacts"
ARTIFACTS_AUTO_PUSH="true"
```

Use `akm config` to view/edit, or `akm setup` for interactive configuration.

## Skill Format

Skills follow the [Agent Skills specification](https://agentskills.io/specification):

```
skills/<name>/
├── SKILL.md           # Entry point (YAML frontmatter + instructions)
└── references/        # Optional supporting files
```

The YAML frontmatter requires `name` and `description` (starting with "Use when...").

## Project Manifests

Declare which skills a project uses in `.agents/akm.json`:

```json
{
  "skills": ["test-driven-development", "systematic-debugging"],
  "agents": ["code-reviewer"]
}
```

These are loaded automatically when you start a session via the shell wrappers.

## Machine Layout

```
~/.local/bin/akm                    # CLI binary
~/.local/share/akm/                 # System data (XDG-compliant)
  ├── skills/                       # Cold library — local package store
  ├── agents/                       # Cold library
  ├── library.json                  # Spec registry
  ├── shell/akm-init.sh            # Shell integration script
  └── global-instructions.md       # User's global instructions
~/.config/akm/config                # All config (flat key=value)
~/.cache/akm/                       # Ephemeral data
  ├── skills-remote/               # Cached clone of SKILLS_REMOTE
  └── <project>-<ts>-<pid>/        # Session staging dirs
~/.akm/artifacts/<repo>/            # Artifact dirs per project
```

## Included Skills

AKM ships with 63+ skills covering:

| Category | Skills |
|----------|--------|
| **Development workflow** | brainstorming, writing-plans, executing-plans, test-driven-development, verification-before-completion |
| **Code quality** | critical-code-reviewer, requesting-code-review, receiving-code-review, systematic-debugging |
| **Git & collaboration** | git-commit, finishing-a-development-branch, using-git-worktrees, pr-create, solve-issue, triage-issues |
| **Multi-agent** | planning-team, implementing-team, dispatching-parallel-agents, subagent-driven-development, solve-batch |
| **Writing & docs** | technical-writer, editor, content-creator, adr-writing |
| **Domain-specific** | R packages, Shiny, Quarto, Rust, Vitest, Supabase, and more |

See `akm skills list` for the full inventory with descriptions.

## Third-Party Attributions

Some included skills were created by or derived from third-party authors:

- Skills by **Garrick Aden-Buie** (@gadenbuie): `cran-extrachecks`, `testing-r-packages`, `lifecycle`, `cli` — MIT License
- **Mickael Canouil** (@mcanouil): `quarto-authoring` — MIT License
- **Anthony Fu** (@antfu): `vitest` — generated from [vitest-dev/vitest](https://github.com/vitest-dev/vitest)
- R language skills derived from **Sarah Johnson** (@sj-io)
- Skills with Apache 2.0 license: `webapp-testing`, `frontend-design`, `skill-creator`, `canvas-design`, `algorithmic-art`, `internal-comms`

See individual skill directories for full license terms.

## License

MIT — see [LICENSE](LICENSE).

## Related Projects

- [Agent Skills Specification](https://agentskills.io/) — The open standard for portable AI coding skills
- [`npx skills`](https://github.com/vercel-labs/skills) — Discover and import skills from GitHub (complementary to AKM)
