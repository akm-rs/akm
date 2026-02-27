---
name: solve-batch
description: "Solve multiple independent GitHub issues in parallel using git worktrees. Dispatches one agent per issue, then blind cross-reviews."
---

# Solve Batch

Solve GitHub issues **$ARGUMENTS** (comma-separated issue numbers) in parallel.
Each issue gets its own git worktree and independent implementation pipeline.

## Prerequisites

- All issues must be open and independent (no file overlaps, no semantic dependencies)
- Verify independence via the triage issue before running this command
- The machine must have enough resources for N parallel agents (recommend max 6)

## Phase 0: Setup (you, the orchestrator)

1. **Parse arguments**: Split `$ARGUMENTS` on commas to get issue numbers. Trim whitespace.
2. **Detect the repo**: Look at CLAUDE.md or run `git remote -v` → `owner/repo`. Use throughout (never hardcode).
3. **Validate issues**: For each issue number, `gh issue view <N> -R <owner/repo> --json state,title,body`. Confirm all are open. Abort if any are closed/missing. Save each issue's title and body — you'll pass them to subagents and reviewers.
4. **Detect the test command**: Look at CLAUDE.md. You'll pass this to subagents.
5. **Detect project conventions**: From CLAUDE.md and any architecture docs, note the key conventions (import patterns, naming, test location, etc.). You'll pass a short summary (~300 tokens) to reviewers.
6. **Generate context brief**: Run the script to write a shared context file:
   ```bash
   .claude/scripts/batch-worktrees.sh context <owner/repo>
   ```
   This reads CLAUDE.md and project docs to generate a brief at `/tmp/<repo-slug>-context-brief.md`. Note the output path.
7. **Create worktrees + install deps**: Run the setup script:
   ```bash
   .claude/scripts/batch-worktrees.sh setup <issue1> <issue2> ...
   ```
   This creates worktrees at `$HOME/<repo-slug>-wt-<N>`, creates `feature/<N>` branches from main, and installs dependencies in parallel. Output is JSON with paths and branches. Parse it.
8. **Verify setup**: Check the script's JSON output. If any worktree failed, abort and report.

## Phase 1: Parallel Dispatch

For each issue, dispatch a **Task subagent** (`model: sonnet`, `subagent_type: general-purpose`) with a prompt that includes:

### Prompt template for each agent:

```
You are solving GitHub issue #<N>.

## Issue
Title: <title>
Body: <body>

## Your Worktree
CRITICAL: You are working in an isolated git worktree at: <absolute-worktree-path>
- ALL file reads, writes, and commands MUST use absolute paths under this directory
- Your branch `feature/<N>` is already checked out
- Dependencies are already installed

## Project Context
Read the context brief at: <context-brief-path>
It contains architecture, conventions, key files, and codebase structure.
Additional rules:
- Repo: <owner/repo> (use -R flag for all gh commands)
- Test command: <detected-test-command> (run from the worktree root)
- When running tests during implementation, prefer targeted tests over the full suite to avoid resource contention with other parallel agents.

## Your Task

1. **Read context**: Read the context brief, then read the source files relevant to this issue
2. **Plan**: Write an implementation plan to <worktree>/plans/<descriptive-name>.md
3. **Implement (TDD)**: Write tests first, see them fail, implement, see them pass. Use TARGETED test runs.
4. **Final verification**: Run the FULL test suite once at the end from the worktree root
5. **Commit**: Commit the plan first, then commit the implementation with conventional commit messages
6. **Push**: `git push -u origin feature/<N>`
7. **Open PR**: `gh pr create -R <owner/repo>` with title, body referencing Closes #<N>
8. **Do NOT post a review comment.** The orchestrator will dispatch a separate blind reviewer after all agents complete.

Report back: PR URL and number, test count, files changed, any issues encountered.
```

**Dispatch ALL agents in a single message** using parallel Task tool calls.

## Phase 2: Collect Results

Wait for all agents to complete. For each, extract:
- PR URL and number (or failure reason)
- Test results (pass/fail, count)
- Files changed count
- Any deviations or issues

## Phase 3: Blind Cross-Review

After all implementation agents complete, dispatch **one Haiku reviewer per PR** in parallel. Each reviewer is blind — it sees only the issue spec, the PR diff, and project conventions. Nothing about the plan or implementation process.

### Inputs to collect (you, the orchestrator):
For each PR, run `gh pr diff <PR-number> -R <owner/repo>` and capture the output. You already have each issue's title/body from Phase 0 and the conventions summary from Phase 0 step 5.

**CRITICAL: Construct each review prompt using ONLY these inputs. Do NOT include plan paths, implementation context, or any details from Phase 1. In batch mode, the orchestrator is deliberately blind to implementation details — the review prompt reflects that.**

### Review prompt template (one per PR):

```
You are reviewing a pull request that claims to solve a GitHub issue.
You have NOT seen the implementation plan or any discussion about this code.
Review the diff purely on its merits against the issue requirements.

## Issue
Title: <title>
Body: <body>

## PR Diff
<output of gh pr diff>

## Project Conventions
<short summary of conventions detected from CLAUDE.md — import patterns, naming, test location, etc.>

## Your Review
Assess:
1. **Issue Coverage**: Does the diff fully address what the issue asks for?
2. **Code Quality**: Clean, minimal, no dead code, no over-engineering?
3. **Test Coverage**: Are there new/updated tests? Do they cover edge cases?
4. **Convention Compliance**: Does the code follow the project patterns above?
5. **Potential Issues / Risks**: Anything that could break, regress, or cause problems?
6. **Verdict**: LGTM / Request Changes (with specific actionable items)

Post your review: gh pr comment <PR-number> -R <owner/repo> --body "<your review>"
```

Dispatch ALL reviewers in a single message (parallel Task tool calls).

Skip this phase only if the user explicitly requests skipping reviews.

### Why blind review in batch mode (unlike two-pass review in single-issue mode)

In single-issue mode, the orchestrator has the plan and can share it with the reviewer for a completeness check. In batch mode, the orchestrator deliberately delegates implementation to independent agents and stays blind to their internal process. The reviewer reflects that — it judges the output (the diff) against the spec (the issue), not the process. This is by design: batch mode prioritizes throughput and independence over deep plan-level review. The human reviewer provides the depth.

## Phase 4: Report

Print a summary table to the user:

```
| Issue | PR | Tests | Files | Review | Status |
|-------|----|----|-------|--------|--------|
| #<N> | #<PR> | <count> pass | <count> | <verdict> | Ready for review |
```

Plus:
- Total wall-clock time for the batch
- Any failures, timeouts, or deviations
- Cleanup command for reference

## Phase 5: Cleanup

Ask the user: "Want me to remove the worktrees?"

If yes, run the teardown script:
```bash
.claude/scripts/batch-worktrees.sh teardown <issue1> <issue2> ...
```

If any removal fails, the script will warn. Report to user.

## Rules

- **Use the scripts for mechanical work.** Worktree creation, dependency installation, cleanup, and context generation are all handled by `.claude/scripts/batch-worktrees.sh`. Do NOT reinvent these steps manually.
- **Max 6 agents on one machine.** Resource contention (CPU, RAM, disk I/O) causes test timeouts beyond this. If the batch is larger, split into sub-batches of 6 and run sequentially.
- **Targeted tests during implementation.** Tell subagents to run targeted test files (not the full suite) during TDD cycles to reduce resource contention. Full suite only at the end.
- **Context brief, not context dump.** Use the generated context brief instead of inlining project context in each prompt. This saves tokens per agent and ensures consistency.
- **Each agent is fully independent.** Give complete context in the prompt — agents can't see your conversation or each other.
- **Worktrees are mandatory.** Never dispatch multiple agents in the same working directory.
- **Validate independence first.** If issues share file dependencies (per triage), they can't be in the same batch. Abort and tell the user.
- **Blind review is mandatory in batch mode.** Review prompts contain ONLY issue spec + PR diff + project conventions. No plan paths, no implementation details. This is enforced by prompt construction.
- **Implementers do NOT self-review.** The agent prompt explicitly says "do NOT post a review." The orchestrator dispatches separate Haiku reviewers after all implementations complete.
- **The human reviews last.** Automated tests → blind LLM review → human approval. Don't merge anything.
- **Don't over-read.** You only need issue bodies + the context brief path. Don't read source files — the subagents will do that.
