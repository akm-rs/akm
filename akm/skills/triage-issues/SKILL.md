---
name: triage-issues
description: "Solve a GitHub issue end-to-end: plan, implement (TDD), review, open PR. Uses subagents for each phase."
---

# Solve Issue

Solve GitHub issue **#$ARGUMENTS** from the repo end-to-end using a multi-agent loop. You are the **orchestrator**. You read context, dispatch subagents, and open the PR. Each agent writes permanent artifacts.

## Phase 0: Context Gathering (you, the orchestrator)

1. **Detect the repo**: Run `git remote -v` to identify the `owner/repo` for `gh` commands. Use this throughout (never hardcode a repo).
2. **Read the issue**: `gh issue view $ARGUMENTS -R <owner/repo> --json title,body,labels,state`. Save the title and body — you'll need them for the review phase.
3. **Read project context** — CLAUDE.md or AGENTS.md is already in your system prompt. Use it to find whatever project docs exist (architecture docs, repo maps, implementation logs, etc.). Read only what you need to brief the planning agent — don't overload your context.
4. **Detect the test command**: You'll pass this to subagents.
5. **Detect project conventions**: From CLAUDE.md and any architecture docs, note the key conventions (import patterns, naming, test location, etc.). You'll pass a short summary (~300 tokens) to the reviewer.
6. **Create the feature branch**: `git checkout -b feature/$ARGUMENTS-<short-description>` from the main branch.

Stop here and assess: do you have enough context to brief the planning agent? If the issue references specific files, skim them. Otherwise, move on.

## Phase 1: Planning (dispatch planning subagent)

Dispatch a **Task subagent** (`model: gpt 5.3 codex xhigh or opus-4.6 if you are claude code`, `subagent_type: general-purpose`) with a detailed prompt that includes:

- The full issue title and body
- Relevant codebase context (architecture patterns, key files, conventions)
- Instructions to **read the actual source files** it needs before writing the plan
- Instructions to write the plan to the agents plans folder : `<descriptive-name>.md`

The planning agent must:

- Read existing code to understand patterns and conventions
- Write a detailed implementation plan covering: overview, architecture decisions, numbered tasks, testing strategy (TDD), exit criteria
- Follow any project-specific rules from CLAUDE.md (naming conventions, import patterns, etc.)

**Artifact**: `<plans-folder>/<name>.md` committed to the repo. Note the path — you'll pass it to the reviewer in Phase 4.

## Phase 2: Plan review (dispatch plan review subagent)

After the plan is written, dispatch a **second Task subagent** (`model: haiku-4.5`, `subagent_type: general-purpose`) with:

- Reference to the plan file path
- Any project-specific conventions from CLAUDE.md (import patterns, naming, etc.)

### Inputs to collect (you, the orchestrator)

1. **Issue title and body**: From Phase 0.
2. **Plan file path**: From Phase 1 (the plan written to `plans/<name>.md`).
3. **Project conventions**: The short summary you detected in Phase 0 step 5.

### Review prompt template

```
You are reviewing an implementation-plan proposal to solve a GitHub issue.

## Issue
Title: <title>
Body: <body>

## Plan : <plan-path>

## Project Conventions
<short summary of conventions from CLAUDE.md — import patterns, naming, test location, etc.>

Review the plan on its own merits against the issue requirements:
1. **Issue Coverage**: Does the diff fully address what the issue asks for?
2. **Plan Quality**: Atomic tasks, anticipated tests, anticipated difficulties and edge cases, no drift, no over-engineering?
4. **Convention Compliance**: Does the plan follow the project patterns listed above?
5. **Risks**: Anything that could break, regress, or cause problems?

Write findings to a file next to the plan `<plan-name><-review>.md`

## Verdict

Write your review to a file next to the plan `<plan-name><-review>.md`
```

You (the orchestrator) read the review and, if there are changes requested, dispatch a new planning agent to include them in the final plan.

## Phase 3: Implementation (dispatch implementation subagent)

After the plan is validated, dispatch a **Task subagent** (`model: gpt 5.3 codex xhigh or opus-4.6 if you are claude code`, `subagent_type: general-purpose`) with:

- Reference to the plan file path
- Explicit instruction to follow the plan's implementation order
- TDD methodology: write tests first, run the test command to see red, implement, run tests to see green
- The test command you detected in Phase 0
- Instructions to read every file before modifying it
- Any project-specific conventions from CLAUDE.md (import patterns, naming, etc.)
- Instruction to **NOT commit** — you (the orchestrator) handle git
- Instruction to **NOT modify documentation/agent docs** — you handle that too

The implementation agent must:

- Follow the plan step by step
- Run tests after each implementation step
- Report back: final test count, files modified/created, any deviations from plan

**Artifact**: Code changes in the working tree (you commit them).

## Phase 4: Commit, Push, and Open PR (you, the orchestrator)

1. **Verify tests pass**: Run the test command yourself to confirm (only check the last lines to verify and save tokens, and the full log only if there are problems)
2. **Commit the plan**: `git add plans/<name>.md && git commit -m "docs: add implementation plan for <feature> (#$ARGUMENTS)"`
3. **Commit the implementation**: Stage all changed/new source files and commit with:

   ```
   feat: <concise description> (#$ARGUMENTS)

   - bullet points summarizing key changes
   - test count
   ```

4. **Push**: `git push -u origin <branch-name>`
5. **Open PR**: `gh pr create -R <owner/repo>` with:
   - Title: `feat: <description> (#$ARGUMENTS)`
   - Body: Summary section with bullet points, files changed table, test plan checklist
   - Reference: `Closes #$ARGUMENTS`

Note the PR number — you'll need it for Phase 4.

**Artifact**: PR with informative title/body referencing the issue.

## Phase 5: Two-Pass Code Review (dispatch Haiku subagent)

After the PR is open, dispatch a **third Task subagent** (`model: haiku-4.5`, `subagent_type: general-purpose`) for a **two-pass review**. The reviewer first assesses the diff independently, then checks it against the plan for completeness.

### Inputs to collect (you, the orchestrator)

1. **Issue title and body**: From Phase 0.
2. **PR diff**: Run `gh pr diff <PR-number> -R <owner/repo>` and capture the output.
3. **Plan file path**: From Phase 1 (the plan written to `plans/<name>.md`).
4. **Project conventions**: The short summary you detected in Phase 0 step 5.

### Review prompt template

```
You are reviewing a pull request that claims to solve a GitHub issue.
Your review has two passes. Complete Pass 1 fully before reading the plan in Pass 2.

## Issue
Title: <title>
Body: <body>

## PR Diff
<output of gh pr diff>

## Project Conventions
<short summary of conventions from CLAUDE.md — import patterns, naming, test location, etc.>

## Pass 1: Independent Assessment (do this FIRST, before reading the plan)

Review the diff on its own merits against the issue requirements:
1. **Issue Coverage**: Does the diff fully address what the issue asks for?
2. **Code Quality**: Clean, minimal, no dead code, no over-engineering?
3. **Test Coverage**: Are there new/updated tests? Do they cover edge cases?
4. **Convention Compliance**: Does the code follow the project patterns listed above?
5. **Risks**: Anything that could break, regress, or cause problems?

Write your Pass 1 findings before proceeding.

## Pass 2: Plan Completeness Check

Now read the implementation plan at: <plan-file-path>

Compare the plan to the diff:
6. **Completeness**: Did the implementation miss anything the plan identified?
7. **Deviations**: Did the implementation deviate from the plan? Is the deviation justified or a gap?
8. **Edge cases**: Did the plan identify edge cases that the tests don't cover?

## Verdict

Synthesize both passes:
- Pass 1 findings (independent quality)
- Pass 2 findings (plan adherence)
- Final verdict: LGTM / Request Changes (with specific actionable items)

Post your review: gh pr comment <PR-number> -R <owner/repo> --body "<your review>"
```

**Why two-pass**: Pass 1 catches code quality issues that the plan can't reveal. Pass 2 catches completeness gaps that blind review would miss. The plan is the captured analysis from the Opus planner — withholding it from the reviewer wastes that work.

**Artifact**: Review comment on the PR.

## Phase 6: Report (you, the orchestrator)

Summarize to the user:

- PR URL
- Test results
- Files changed count
- Review verdict
- Any issues flagged

## Rules

- **Each agent writes permanent artifacts**: planner writes `plans/`, implementer writes code, reviewer write plan review and comments on PR, orchestrator opens PR
- **Don't overload context**: read only what you need at each phase
- **Subagents are independent**: give them complete context in their prompt — they can't see your conversation
- **TDD is non-negotiable**: tests before implementation
- **Branch from main**: never commit to main directly
- **Respect project conventions**: CLAUDE.md rules override defaults — pass them to subagents
- **Two-pass review structure is mandatory**: the reviewer must form an independent assessment (Pass 1) before consulting the plan (Pass 2). This prevents confirmation bias while still catching completeness gaps.
