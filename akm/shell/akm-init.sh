#!/bin/bash
# akm-init.sh — Source this file in your .bashrc to enable AKM session lifecycle
# and LLM tool wrappers (claude, copilot, opencode).
#
# Usage (added automatically by akm setup):
#   source ~/.local/share/akm/shell/akm-init.sh

# --- Config ---

_akm_load_config() {
  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/akm/config"
  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    source "$config_file"
  fi
}

_akm_feature_enabled() {
  local feature="$1"
  local features="${FEATURES:-}"
  [[ ",$features," == *",$feature,"* ]]
}

# --- Git helpers ---

_akm_in_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

_akm_project_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

_akm_repo_name() {
  basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || true
}

# --- Skills session ---

_akm_create_session_symlink() {
  local id="$1"
  local staging="$2"
  local library_dir="${XDG_DATA_HOME:-$HOME/.local/share}/akm"
  local library_json="$library_dir/library.json"

  if [[ ! -f "$library_json" ]]; then
    return 1
  fi

  local type
  type="$(jq -r --arg id "$id" '.specs[] | select(.id == $id) | .type' "$library_json")"

  if [[ -z "$type" || "$type" == "null" ]]; then
    return 1
  fi

  local subdir source_path
  case "$type" in
    skill)
      subdir="skills"
      source_path="$library_dir/skills/$id"
      ;;
    agent)
      subdir="agents"
      source_path="$library_dir/agents/${id}.md"
      ;;
    *) return 1 ;;
  esac

  if [[ ! -e "$source_path" ]]; then
    return 1
  fi

  local tool_dir
  for tool_dir in .claude .copilot .agents; do
    local target_dir="$staging/$tool_dir/$subdir"
    if [[ "$type" == "skill" ]]; then
      ln -sfn "$source_path" "$target_dir/$id"
    else
      ln -sf "$source_path" "$target_dir/${id}.md"
    fi
  done
}

_akm_skills_session_start() {
  local project_root
  project_root="$(_akm_project_root)"
  if [[ -z "$project_root" ]]; then
    return 1
  fi

  local project_name
  project_name="$(_akm_repo_name)"
  local session_id="${project_name:-anon}-$(date +%s)-$$"
  local staging="$HOME/.cache/akm/$session_id"

  # Create staging directory structure
  local tool_dir
  for tool_dir in .claude .copilot .agents; do
    mkdir -p "$staging/$tool_dir"/{skills,agents}
  done

  # Load specs from project manifest
  local manifest="$project_root/.agents/akm.json"
  if [[ -f "$manifest" ]] && command -v jq &>/dev/null; then
    local id
    while IFS= read -r id; do
      [[ -n "$id" ]] && _akm_create_session_symlink "$id" "$staging" || true
    done < <(jq -r '.skills // [] | .[]' "$manifest" 2>/dev/null)

    while IFS= read -r id; do
      [[ -n "$id" ]] && _akm_create_session_symlink "$id" "$staging" || true
    done < <(jq -r '.agents // [] | .[]' "$manifest" 2>/dev/null)
  fi

  export AKM_SESSION="$staging"
}

_akm_skills_session_end() {
  if [[ -n "${AKM_SESSION:-}" && -d "$AKM_SESSION" ]]; then
    rm -rf "$AKM_SESSION"
  fi
  unset AKM_SESSION
}

# --- Artifacts lifecycle ---

# Ensure artifact directory for current project exists.
# Prints the artifact dir path to stdout. Returns 1 if not in a git repo.
_akm_artifacts_ensure_dir() {
  local artifacts_dir="${ARTIFACTS_DIR:-$HOME/.akm/artifacts}"
  local repo_name
  repo_name="$(_akm_repo_name)"

  if [[ -z "$repo_name" ]]; then
    return 1
  fi

  local artifact_dir="$artifacts_dir/$repo_name"
  if [[ ! -d "$artifact_dir" ]]; then
    mkdir -p "$artifact_dir"
  fi
  echo "$artifact_dir"
}

# Pull artifacts on session start (no push, to avoid delay).
_akm_artifacts_pull() {
  local artifacts_dir="${ARTIFACTS_DIR:-$HOME/.akm/artifacts}"
  if [[ -d "$artifacts_dir/.git" ]]; then
    git -C "$artifacts_dir" pull --rebase --autostash --quiet 2>/dev/null || true
  fi
}

# Auto-commit and push artifacts on session exit.
_akm_artifacts_commit_and_push() {
  local artifacts_dir="${ARTIFACTS_DIR:-$HOME/.akm/artifacts}"
  local repo_name
  repo_name="$(_akm_repo_name)"

  if [[ ! -d "$artifacts_dir/.git" ]]; then
    return 0
  fi

  local has_changes=false
  if ! git -C "$artifacts_dir" diff --quiet 2>/dev/null; then
    has_changes=true
  fi
  if [[ -n "$(git -C "$artifacts_dir" ls-files --others --exclude-standard 2>/dev/null)" ]]; then
    has_changes=true
  fi

  if [[ "$has_changes" == true ]]; then
    git -C "$artifacts_dir" add -A
    git -C "$artifacts_dir" commit -m "${repo_name:-misc}: $(date +%Y-%m-%d-%H%M)" --quiet 2>/dev/null || true
    git -C "$artifacts_dir" pull --rebase --autostash --quiet 2>/dev/null || true
    git -C "$artifacts_dir" push --quiet 2>/dev/null &
  fi
}

# --- Session orchestration ---

_akm_session_start() {
  _akm_load_config

  local artifact_dir=""
  local staging_dir=""

  if _akm_in_git_repo; then
    # Artifacts: pull and ensure project dir
    if _akm_feature_enabled "artifacts"; then
      _akm_artifacts_pull
      artifact_dir="$(_akm_artifacts_ensure_dir)" || true
    fi

    # Skills: create staging dir
    if _akm_feature_enabled "skills"; then
      _akm_skills_session_start
      staging_dir="${AKM_SESSION:-}"
    fi
  fi

  # Export for use in _akm_session_end and _akm_wrap_tool
  export _AKM_ARTIFACT_DIR="${artifact_dir}"
  export _AKM_STAGING_DIR="${staging_dir}"
}

_akm_session_end() {
  _akm_load_config

  # Skills cleanup
  if [[ -n "${_AKM_STAGING_DIR:-}" ]]; then
    _akm_skills_session_end
  fi

  # Artifacts: commit and push if auto-push enabled
  if _akm_feature_enabled "artifacts" && [[ "${ARTIFACTS_AUTO_PUSH:-true}" == "true" ]]; then
    if _akm_in_git_repo; then
      _akm_artifacts_commit_and_push
    fi
  fi

  unset _AKM_ARTIFACT_DIR _AKM_STAGING_DIR
}

# --- Tool wrapper ---

_akm_wrap_tool() {
  local tool="$1"; shift

  _akm_session_start

  local cmd=(command "$tool")
  [[ -n "${_AKM_ARTIFACT_DIR:-}" ]] && cmd+=(--add-dir "$_AKM_ARTIFACT_DIR")
  [[ -n "${_AKM_STAGING_DIR:-}" ]] && cmd+=(--add-dir "$_AKM_STAGING_DIR")
  cmd+=("$@")

  "${cmd[@]}"
  local exit_code=$?

  _akm_session_end
  return $exit_code
}

# --- Exported wrappers ---

claude()   { _akm_wrap_tool claude   "$@"; }
copilot()  { _akm_wrap_tool copilot  "$@"; }
opencode() { _akm_wrap_tool opencode "$@"; }
