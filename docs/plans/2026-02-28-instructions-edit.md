# `akm instructions edit` Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `akm instructions edit` to open the global instructions file in the user's editor, and move the file to `~/.akm/` for discoverability.

**Architecture:** Single-file change to `bin/akm`. Move the instructions path from `${XDG_DATA_HOME}/akm/` to `~/.akm/`, add migration logic, add `edit` subcommand with editor resolution and post-edit sync prompt.

**Tech Stack:** Bash

---

### Task 1: Update instructions path in `cmd_instructions_sync`

**Files:**
- Modify: `bin/akm:512-518`

**Step 1: Change the path and warning message**

Replace lines 512-518:

```bash
cmd_instructions_sync() {
  local source_file="$HOME/.akm/global-instructions.md"

  # Migrate from old XDG location
  local old_file="${XDG_DATA_HOME:-$HOME/.local/share}/akm/global-instructions.md"
  if [[ -f "$old_file" && ! -f "$source_file" ]]; then
    mkdir -p "$HOME/.akm"
    mv "$old_file" "$source_file"
    echo -e "${GREEN}Migrated global instructions to $source_file${NC}"
  fi

  if [[ ! -f "$source_file" ]]; then
    echo -e "${YELLOW}Warning: No global instructions file found at $source_file${NC}" >&2
    echo -e "${DIM}Run 'akm instructions edit' to create one.${NC}" >&2
    return 0
  fi
```

**Step 2: Verify sync still works**

Run: `akm instructions sync`
Expected: same behavior as before (distributes to tool dirs), or warns if file missing

**Step 3: Commit**

```bash
git add bin/akm
git commit -m "refactor: move global instructions path to ~/.akm/"
```

---

### Task 2: Update instructions path in `cmd_setup`

**Files:**
- Modify: `bin/akm:698-708`

**Step 1: Change the path in setup**

Replace lines 698-708:

```bash
      # Create empty global-instructions.md if it doesn't exist
      local instructions_file="$HOME/.akm/global-instructions.md"

      # Migrate from old XDG location
      local old_file="${XDG_DATA_HOME:-$HOME/.local/share}/akm/global-instructions.md"
      if [[ -f "$old_file" && ! -f "$instructions_file" ]]; then
        mkdir -p "$HOME/.akm"
        mv "$old_file" "$instructions_file"
        echo -e "  ${GREEN}Migrated global instructions to $instructions_file${NC}"
      fi

      if [[ ! -f "$instructions_file" ]]; then
        mkdir -p "$(dirname "$instructions_file")"
        touch "$instructions_file"
        echo -e "  ${GREEN}Instructions enabled${NC}"
        echo -e "  ${DIM}Created $instructions_file (edit with 'akm instructions edit')${NC}"
      else
        echo -e "  ${GREEN}Instructions enabled${NC}"
        echo -e "  ${DIM}Instructions file exists at $instructions_file${NC}"
      fi
```

**Step 2: Verify setup still works**

Run: `akm setup --instructions`
Expected: shows correct `~/.akm/` path

**Step 3: Commit**

```bash
git add bin/akm
git commit -m "refactor: update setup to use ~/.akm/ for instructions"
```

---

### Task 3: Add `cmd_instructions_edit` function

**Files:**
- Modify: `bin/akm` — insert new function after `cmd_instructions_scaffold_project` (after line 567)

**Step 1: Add the edit function**

Insert after line 567 (after the closing `}` of `cmd_instructions_scaffold_project`):

```bash

cmd_instructions_edit() {
  local instructions_file="$HOME/.akm/global-instructions.md"

  # Migrate from old XDG location
  local old_file="${XDG_DATA_HOME:-$HOME/.local/share}/akm/global-instructions.md"
  if [[ -f "$old_file" && ! -f "$instructions_file" ]]; then
    mkdir -p "$HOME/.akm"
    mv "$old_file" "$instructions_file"
    echo -e "${GREEN}Migrated global instructions to $instructions_file${NC}"
  fi

  # Create with starter header if it doesn't exist
  if [[ ! -f "$instructions_file" ]]; then
    mkdir -p "$(dirname "$instructions_file")"
    echo "# Global LLM Instructions" > "$instructions_file"
  fi

  # Resolve editor: $EDITOR > git's editor > nano
  local editor="${EDITOR:-$(git var GIT_EDITOR 2>/dev/null || echo "nano")}"

  "$editor" "$instructions_file"

  # Prompt to sync after editing
  local sync_answer
  read -rp "Sync changes to tool directories? [Y/n]: " sync_answer
  sync_answer="${sync_answer:-Y}"
  if [[ "$sync_answer" =~ ^[Yy]$ ]]; then
    cmd_instructions_sync
  fi
}
```

**Step 2: Verify it works**

Run: `akm instructions edit`
Expected: opens editor, after closing prompts to sync

**Step 3: Commit**

```bash
git add bin/akm
git commit -m "feat: add akm instructions edit command"
```

---

### Task 4: Wire up the subcommand and help text

**Files:**
- Modify: `bin/akm:489-498` (the `cmd_instructions` dispatcher)

**Step 1: Add edit to the case statement and help**

Replace the case block (lines 489-498):

```bash
  case "$subcommand" in
    edit)             cmd_instructions_edit "$@" ;;
    sync)             cmd_instructions_sync "$@" ;;
    scaffold-project) cmd_instructions_scaffold_project "$@" ;;
    help|--help|-h)
      echo "Usage: akm instructions <subcommand>"
      echo ""
      echo "Subcommands:"
      echo "  edit              Edit global instructions file in \$EDITOR"
      echo "  sync              Distribute global instructions to tool dirs"
      echo "  scaffold-project  Create AGENTS.md + CLAUDE.md in project root"
      ;;
```

**Step 2: Verify help output**

Run: `akm instructions help`
Expected: shows `edit` in the subcommand list

**Step 3: Commit**

```bash
git add bin/akm
git commit -m "feat: wire up instructions edit subcommand"
```
