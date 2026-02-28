# AKM — Agent Kit Manager

A CLI tool for managing reusable [Agent Skills](https://agentskills.io/), LLM session artifacts, and global instructions across LLM-powered coding assistants (Claude Code, GitHub Copilot CLI, OpenCode, and more).

## Features

- **Skills management** — Cold library with three-layer activation (core/project/session) and per-session isolation
- **Skillverse** — Ships with a default community skills registry; just run `akm setup` and go
- **Artifact sync** — Auto-sync LLM session outputs (plans, research, notes) to a git repo
- **Global instructions** — Write once, distribute to all tool directories
- **Multi-tool support** — Works with Claude Code, GitHub Copilot CLI, OpenCode, and any tool that reads from dotfile directories

## Prerequisites

- **jq** — `sudo apt-get install jq` or `brew install jq`
- **git** — For skills sync, repo detection, and artifact sync

## Quick Start

```bash
# Clone and install
git clone https://github.com/akm-rs/akm ~/akm
bash ~/akm/install.sh

# Configure (interactive — defaults work out of the box)
akm setup

# Open a new terminal (or source ~/.bashrc), then:
akm skills status
```

Setup asks three things: enable skills (Y), use Skillverse (Y), enable artifacts/instructions. The happy path is Enter through everything.

## How It Works

### Three Domains

AKM manages three independent subsystems. Each is enableable via `akm setup` and disabling one never affects the others.

| Domain | Purpose | Key command |
|--------|---------|-------------|
| **Skills** | Install and activate LLM skills/agents | `akm skills sync` |
| **Artifacts** | Sync session outputs to a git repo | `akm artifacts sync` |
| **Instructions** | Distribute global LLM instructions | `akm instructions sync` |

### Skills: Three-Layer Activation

```
Layer 1 — Core (global, always available)
  Specs marked core=true in library.json
  Symlinked into ~/.claude/, ~/.copilot/, ~/.agents/, ~/.vibe/

Layer 2 — Project (declared in manifest, loaded at session start)
  .agents/akm.json lists skill/agent IDs
  Shell wrapper reads manifest → symlinks into per-session staging dir

Layer 3 — Session (JIT, mid-session)
  akm skills load <id>   → adds to active staging dir
  akm skills unload <id> → removes from staging dir
```

### Shell Wrappers

`akm setup` wires `akm-init.sh` into your `.bashrc`, which provides wrapper functions for `claude`, `copilot`, and `opencode`. These wrappers automatically:

1. Pull latest artifacts (if enabled)
2. Create a per-session skills staging directory with manifest specs loaded
3. Pass artifact and staging dirs to the tool via `--add-dir`
4. On exit: destroy staging dir, commit+push artifacts (if auto-push enabled)

## CLI Reference

```
akm <command> [subcommand] [options]

Setup & Config:
  setup [--skills|--artifacts|--instructions]   Interactive configuration
  config [key] [value]                          View/get/set config
  sync                                          Sync all enabled domains
  help                                          Show help

Skills:
  skills sync                    Pull remote → cold library → rebuild symlinks
  skills add <id> [id...]        Add spec(s) to project manifest
  skills remove <id> [id...]     Remove spec(s) from project manifest
  skills load <id> [id...]       Load spec(s) into active session (JIT)
  skills unload <id> [id...]     Remove spec(s) from active session
  skills loaded                  Show active session specs with provenance
  skills list [--tag TAG] [--type TYPE]   Browse library
  skills search <query>          Search by keyword
  skills status                  Full status overview
  skills clean [--project] [--dry-run]    Remove stale specs
  skills clean --project --migrate        Migrate legacy copies to manifest
  skills publish <id> [--dry-run] [--force]   Publish spec as PR to remote
  skills libgen                  Regenerate library.json from disk

Artifacts:
  artifacts sync                 Bidirectional sync with artifacts remote

Instructions:
  instructions edit              Edit global instructions in $EDITOR
  instructions sync              Distribute to all tool directories
  instructions scaffold-project  Create AGENTS.md + CLAUDE.md in project root
```

## Configuration

All config lives in `~/.config/akm/config` (flat key=value, sourceable by bash):

```bash
FEATURES="skills,artifacts,instructions"
SKILLS_REMOTE="https://github.com/akm-rs/skillverse.git"
ARTIFACTS_REMOTE="git@github.com:user/llm-artifacts.git"
ARTIFACTS_DIR="$HOME/.akm/artifacts"
ARTIFACTS_AUTO_PUSH="true"
```

| Key | Description |
|-----|-------------|
| `features` | Enabled domains (comma-separated) |
| `skills.remote` | Git remote for skills library. Defaults to [Skillverse](https://github.com/akm-rs/skillverse) if unset |
| `artifacts.remote` | Git remote for artifacts repo |
| `artifacts.dir` | Local artifacts directory |
| `artifacts.auto-push` | Auto commit+push artifacts on session exit (`true`/`false`) |

Use `akm config` to view all, `akm config <key>` to get, `akm config <key> <value>` to set.

## Skill Format

Skills follow the [Agent Skills specification](https://agentskills.io/specification):

```
skills/<name>/
├── SKILL.md           # Entry point (YAML frontmatter + instructions)
└── references/        # Optional supporting files
```

Frontmatter requires `name` and `description` (convention: starts with "Use when..."):

```yaml
---
name: Test-Driven Development
description: Use when implementing any feature or bugfix, before writing implementation code
---
```

Agents are single `.md` files in `agents/` with the same frontmatter format.

## Project Manifests

Declare which skills a project uses in `.agents/akm.json`:

```json
{
  "skills": ["test-driven-development", "systematic-debugging"],
  "agents": ["code-reviewer"]
}
```

These are loaded automatically when you start a session via the shell wrappers. Manage with `akm skills add/remove <id>`.

## Machine Layout

```
~/.local/bin/akm                        # CLI binary
~/.local/share/akm/                     # Cold library (XDG_DATA_HOME)
  ├── skills/                           # Installed skills
  ├── agents/                           # Installed agents
  ├── library.json                      # Generated spec registry
  └── shell/akm-init.sh                # Shell integration
~/.config/akm/config                    # Configuration (XDG_CONFIG_HOME)
~/.cache/akm/                           # Ephemeral data (XDG_CACHE_HOME)
  ├── skills-remote/                    # Cached clone of skills remote
  └── <project>-<ts>-<pid>/            # Session staging dirs
~/.akm/
  ├── global-instructions.md            # Global LLM instructions
  └── artifacts/<repo>/                 # Artifact dirs per project
```

## Publishing Skills

To publish a project-local skill to your skills remote:

```bash
akm skills publish my-skill
```

This validates frontmatter, copies the spec to a `publish/my-skill` branch in the cached skills remote, commits, pushes, and opens a PR via `gh`.

Use `--dry-run` to preview and `--force` to overwrite an existing spec.

## License

MIT — see [LICENSE](LICENSE).

## Related Projects

- [Agent Skills Specification](https://agentskills.io/) — The open standard for portable AI coding skills
- [Skillverse](https://github.com/akm-rs/skillverse) — AKM's community skills registry
- [`npx skills`](https://github.com/vercel-labs/skills) — Discover and import skills from GitHub
- [Anthropic Skills Marketplace](https://github.com/anthropics/skills) — Anthropic's official skill collection
- [SkillsMP](https://skillsmp.com/) — Community marketplace for agent skills
