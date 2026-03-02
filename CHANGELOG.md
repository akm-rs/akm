# Changelog

All notable changes to AKM will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.1.1] - 2026-03-02

### Fixed
- `akm skills clean --project` now cleans all project-level tool directories (`.claude/`, `.github/`, `.agents/`, `.vibe/`), not just `.claude/`
- `akm skills clean --project` now prompts for confirmation before removing specs not found in the cold library
- `akm skills sync` now preserves user's local `core` flag overrides — registries update names, descriptions, and tags, but `core` stays as the user set it

### Changed
- Added `PROJECT_TOOL_DIRS` constant for consistent project-level directory handling across `_copy_spec_to_project()`, `cmd_skills_migrate()`, and `_clean_project()`
