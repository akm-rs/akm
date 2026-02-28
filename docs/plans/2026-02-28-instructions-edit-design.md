# Design: `akm instructions edit`

## Summary

Add an `edit` subcommand to `akm instructions` that opens the global instructions file in the user's editor, then prompts to sync. Also move the global instructions file from the XDG data dir to `~/.akm/` for discoverability.

## Changes

### 1. Move global instructions path

- **Old:** `${XDG_DATA_HOME:-$HOME/.local/share}/akm/global-instructions.md`
- **New:** `$HOME/.akm/global-instructions.md`
- Rationale: this is a user-edited file, not app-managed data. `~/.akm/` is discoverable like `~/.ssh/` or `~/.gitconfig`.
- Touch points: `cmd_instructions_sync`, `cmd_setup` instructions block, new `cmd_instructions_edit`

### 2. Migration

- If old path exists and new path doesn't, move it automatically (on first `edit` or `sync`)

### 3. New subcommand: `akm instructions edit`

- Resolve editor: `${EDITOR:-$(git var GIT_EDITOR 2>/dev/null || echo "nano")}`
- If file doesn't exist, create with minimal header (`# Global LLM Instructions`)
- Open editor on the file
- After editor exits, prompt: `Sync changes to tool directories? [Y/n]`
- If yes (default), call `cmd_instructions_sync`

### 4. Help text

- Add `edit` to `cmd_instructions` help output

## Files changed

- `bin/akm` only
