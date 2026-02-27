# AGENTS.md

This file provides guidance to LLMs working with code in this repository.

## What This Repo Is

AKM (Agent Kit Manager) is a CLI tool for managing reusable
[Agent Skills](https://agentskills.io/), LLM session artifacts, and global
instructions across LLM-powered coding assistants.

It provides three independent domains: skills (cold storage, three-layer
activation, session isolation), artifacts (auto-sync session outputs), and
instructions (global LLM instruction distribution).

## Key Commands

```bash
bash install.sh          # Bootstrap: copy binary + shell init
akm setup                # Interactive feature configuration
akm sync                 # Sync all enabled subsystems
akm skills status        # Show skills overview
akm skills list          # Browse available skills
akm artifacts sync       # Sync artifacts repo
akm instructions sync    # Distribute global instructions
akm config               # View/edit config
```

No build system, test suite, or CI/CD. All scripts are pure Bash.

## Repository Map

```
akm/
├── bin/akm                # CLI (~1800 lines Bash, set -euo pipefail)
├── shell/akm-init.sh      # Shell functions sourced in .bashrc
├── skills/                # 65+ skills (SKILL.md + optional references/)
├── agents/                # Agent definitions (single .md files)
├── library.json           # Registry of all specs with metadata
├── install.sh             # Bootstrap installer (~25 lines)
├── README.md              # Public documentation
├── LICENSE                # MIT
└── AGENTS.md              # This file
```

### Key Files

| File | Purpose |
|------|---------|
| `bin/akm` | Main CLI — all commands (setup, config, sync, skills/artifacts/instructions domains) |
| `shell/akm-init.sh` | Session lifecycle + tool wrappers (claude, copilot, opencode) |
| `library.json` | Registry with id, type, description, tags, core flag per spec |
| `install.sh` | Bootstrap: copies binary + shell init, prints "run akm setup" |

## Architecture

### Three Domains

```
Skills       — Cold library, three-layer activation, session staging
Artifacts    — Bidirectional git sync of session outputs
Instructions — Distribute global instructions to tool directories
```

Each domain is independent. Disabling one does not affect the others.

### Config

All runtime decisions read from `~/.config/akm/config` (flat key=value, sourceable by bash):

```bash
FEATURES="skills,artifacts,instructions"
SKILLS_REMOTE="git@github.com:user/skills-library.git"
ARTIFACTS_REMOTE="git@github.com:user/llm-artifacts.git"
ARTIFACTS_DIR="$HOME/.akm/artifacts"
ARTIFACTS_AUTO_PUSH="true"
```

### Skills: Three-Layer Activation

```
Layer 1 — Core (global, always available)
  akm skills sync → cold library (~/.local/share/akm/) → global symlinks

Layer 2 — Project (manifest-declared, loaded at session start)
  .agents/akm.json → shell wrapper reads → symlinks into staging dir

Layer 3 — Session (JIT, mid-session)
  akm skills load <id> / akm skills unload <id>
```

### Cold Library

`~/.local/share/akm/` contains `skills/`, `agents/`, and `library.json`.
Core specs (`"core": true`) are symlinked into global tool dirs by `akm skills sync`.
Skills enter the cold library via `akm skills sync` (from SKILLS_REMOTE) or manual drop.

### `akm` CLI Command Structure

| Command | Description |
|---------|-------------|
| `setup` | Interactive feature configuration |
| `sync` | Sync all enabled subsystems |
| `config <key> [value]` | Get or set config values |
| `skills sync` | Pull remote → cold library → rebuild symlinks |
| `skills add/remove <id>` | Manage project manifest |
| `skills load/unload <id>` | JIT session loading |
| `skills loaded` | Show active session specs |
| `skills status` | Full status overview |
| `skills list/search` | Browse library |
| `skills clean` | Remove stale specs |
| `skills publish <id>` | Publish local spec as PR |
| `skills libgen` | Regenerate library.json |
| `artifacts sync` | Bidirectional sync with artifacts remote |
| `instructions sync` | Distribute global instructions |
| `instructions scaffold-project` | Create AGENTS.md + CLAUDE.md in project root |

### Shell Init (`shell/akm-init.sh`)

Defines `claude()`, `copilot()`, `opencode()` wrappers that:
1. Read config to determine enabled features
2. Pull artifacts (if enabled)
3. Create per-session staging dir (if skills enabled)
4. Pass `--add-dir` only for enabled features
5. On exit: destroy staging, commit+push artifacts (if auto-push enabled)

### Data Layout

```
~/.local/bin/akm                    # CLI binary
~/.local/share/akm/                 # Cold library + shell init + global instructions
~/.config/akm/config                # All config
~/.cache/akm/skills-remote/         # Cached clone of SKILLS_REMOTE
~/.cache/akm/<session-id>/          # Ephemeral session staging dirs
~/.akm/artifacts/<repo>/            # Artifact dirs per project
```

## Conventions

- All shell scripts use `set -euo pipefail`
- `jq` is the sole runtime dependency
- Skill frontmatter follows the [Agent Skills spec](https://agentskills.io/specification)
- Commit style: conventional commits, WHY over WHAT
- Adding new specs: create in `skills/` or `agents/` → run `akm skills libgen`
