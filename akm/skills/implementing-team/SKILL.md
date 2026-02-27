---
name: implementing-team
description: "Dispatch an implementation team: Haiku messengers coordinate Opus 4.6 coders (TDD, lean) and Opus 4.6 reviewers to implement tasks from existing plans."
---

# /implementing-team

Dispatch an implementation team to execute existing plans using TDD. A single Opus sub-orchestrator manages all coder-reviewer agents, merging, testing, and PR creation — keeping the main orchestrator lean.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All tasks dispatched simultaneously, each in its own **git worktree** for true isolation. Sub-orchestrator merges branches after.
  - `sequential`: Tasks dispatched one at a time, each as a **separate, fresh agent**. Each coder works in the tree left by the previous one. Use when tasks share files or build on each other.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you — stays lean, never compacts)
│
├── Phase 0: Context Gathering
│   ├── Locate plans + spec file, read project docs
│   ├── Skill Discovery → specs-sync search + load
│   ├── Derive review criteria from spec + docs + plans
│   ├── Ensure feature branch exists
│   └── Detect test command
│
└── Phase 1: Delegate to Implementation Dispatch Sub-Orchestrator
    └── Opus sub-orchestrator (single Task agent)
        ├── Reads spec + plans
        ├── Dispatches one NEW Opus Coder-Reviewer agent PER task
        │   ├── Implements with TDD (red → green → refactor)
        │   ├── Commits implementation
        │   ├── Dispatches Opus Reviewer (critical-code-reviewer methodology)
        │   ├── Applies fixes, loops until LGTM (max 3 rounds)
        │   └── Reports: status, files, tests, decision log
        ├── Merges worktree branches (parallel mode)
        ├── Runs full test suite
        ├── Pushes and opens PR
        └── Returns summary + PR URL to you
```

## Your Role (Orchestrator)

1. **Locate the plans and spec** — each task must have an existing plan. The spec file from `/planning-team` should exist in ARTIFACTS_DIR. If no plan exists, stop and tell the user to run `/planning-team` first.
2. **Prepare context** — read project docs for conventions, detect the test command, discover and load relevant skills, derive review criteria
3. **Create feature branch** if on main: `git checkout -b feature/<description>`
4. **Delegate all implementation work** — dispatch a single Opus sub-orchestrator that handles coder-reviewer dispatch, merging, testing, pushing, and PR creation
5. **Present results** — relay the sub-orchestrator's summary and PR URL to the user

**Context discipline**: After Phase 0, you delegate ALL implementation work. You never read code changes or plan details. Your context stays lean: context gathering notes + summary from sub-orchestrator.

---

## Phase 0: Context Gathering

1. Read project docs (CLAUDE.md, AGENTS.md) for conventions, test command, and coding style
2. **Discover relevant skills**: Run `specs-sync search <terms>` (using terms from the project's stack, frameworks, domain) to find skills that provide expertise for this project's technology. For each relevant skill, run `specs-sync load <id>` to hotload it into the current session. Then read the loaded skills to understand patterns, idioms, and common pitfalls — this knowledge informs review criteria.

   **Do NOT**: record absolute file paths, pass skill paths to subagents, or use any `specs-sync` subcommand other than `search`, `list`, `load`, `unload`, `loaded`, and `status`.
3. Identify the implementation plans from the user's prompt or the artifacts directory
4. Locate the spec file (from `/planning-team`) in ARTIFACTS_DIR — it contains the validated design decisions and user-approved review criteria
5. Detect the test command (from project docs or common patterns like `npm test`, `pytest`, `cargo test`, `go test`, etc.)
6. Ensure you're on a feature branch. If on main, create one: `git checkout -b feature/<description>`
7. **Derive review criteria**: Synthesize review criteria from:
   - **Spec file**: The review criteria co-created with the user during planning
   - **Loaded skills**: Patterns, idioms, and pitfalls for this stack
   - **Project docs**: Conventions, priorities, architectural constraints, testing strategies
   - **Plans**: Risks flagged, complex or novel areas warranting extra scrutiny

   Write the criteria as a short numbered list. These are injected into the sub-orchestrator prompt.

---

## Phase 1: Delegate to Implementation Dispatch Sub-Orchestrator

Dispatch a **single Opus sub-orchestrator** (`model: opus`, `subagent_type: general-purpose`) that manages all implementation work.

This delegation keeps your context lean. You do NOT read code changes, manage review rounds, merge branches, or track individual coder agents. The sub-orchestrator handles everything and returns a summary.

### Sub-Orchestrator Prompt Template

````
You are an implementation dispatch orchestrator. Your job is to dispatch coder-reviewer agents for each task, merge their work, run tests, push, open a PR, and report a summary.

## Spec File

Read this file for the validated design decisions and constraints agreed with the user:
<SPEC_FILE_PATH>

## Implementation Plans

These are the plan files to implement (read each one):
<LIST_OF_PLAN_FILE_PATHS>

## Mode: <parallel|sequential>

## Test Command

<TEST_COMMAND>

## Feature Branch

You are on branch: <BRANCH_NAME>

## Review Criteria

<REVIEW_CRITERIA>

## Project Conventions

<SUMMARY from CLAUDE.md / AGENTS.md — style, patterns, naming, frameworks>

## Working Directory

<ABSOLUTE_PATH_TO_REPO>

## Your Workflow

### Step 1: Read Plans and Spec

Read the spec file and all plan files. Extract per-task information: what to implement, source files, test cases.

### Step 2: Dispatch Coder-Reviewer Agents

You will dispatch exactly **one NEW Task subagent per task** (`model: opus`, `subagent_type: general-purpose`). Each subagent runs the full coder-reviewer cycle for its assigned task ONLY. Each agent gets a fresh context — this is critical for code quality.

**If mode is `parallel`**: Dispatch ALL agents in a **single response**, each with `isolation: "worktree"`. Each agent works in complete file-system isolation — no conflict risk.

**If mode is `sequential`**: For EACH task, in order:
  1. Dispatch ONE new Task subagent with the task-specific prompt below
  2. Wait for it to complete and report back with status, files, tests, and decision log
  3. Note any context from the completed task that the next agent needs (e.g., newly created files, function names, design decisions)
  4. Dispatch a NEW Task subagent for the next task, including relevant context from prior tasks in its prompt

**CRITICAL — BOTH MODES**: You dispatch a **separate, fresh agent** for each task. You do NOT implement tasks yourself. You do NOT ask a single agent to implement multiple tasks. Each agent gets ONE task, implements it, gets it reviewed, and reports back. This ensures each agent has a clean, focused context.

#### Sequential Dispatch Example

For sequential mode with 3 tasks, you do this:

```
# Task 1 — dispatch NEW agent
Task(prompt="You are a coder-reviewer agent... Task: Task 1 ...", model=opus)
→ Wait for completion → receive report

# Task 2 — dispatch NEW agent (fresh context)
Task(prompt="You are a coder-reviewer agent... Task: Task 2 ...
  Prior context: Task 1 created R/foo.R with functions bar(), baz()...", model=opus)
→ Wait for completion → receive report

# Task 3 — dispatch NEW agent (fresh context)
Task(prompt="You are a coder-reviewer agent... Task: Task 3 ...
  Prior context: Tasks 1-2 created R/foo.R, R/qux.R ...", model=opus)
→ Wait for completion → receive report

# All done — merge/verify/push/PR
```

Each dispatch is a NEW independent agent. You NEVER continue implementation inside a single agent across multiple tasks.

#### Coder-Reviewer Agent Prompt

```
You are a coder-reviewer agent. Implement ONE task from an existing plan using strict TDD, get your work reviewed, and iterate until approved.

**SCOPE**: You will implement ONLY the task named "<TASK_NAME>" below. You will NOT implement any other tasks. When you have completed this ONE task (tests passing, reviewer approves), report back with your status. The orchestrator will dispatch a separate agent for the next task.

## Task: <TASK_NAME>

## Implementation Plan

Read the plan FIRST: <PLAN_FILE_PATH>

## Spec File

Read this for the full validated spec (design decisions, constraints, review criteria):
<SPEC_FILE_PATH>

## Project Conventions

<CONVENTIONS>

## Test Command

<TEST_COMMAND>

## Review Criteria

The following criteria were co-created with the user. The reviewer will evaluate your code against them.

<REVIEW_CRITERIA>

## Prior Task Context (sequential mode only)

<PRIOR_CONTEXT — files created by previous agents, key function names, decisions made. Empty for the first task.>

## Working Directory

<ABSOLUTE_PATH_TO_REPO>

## Your Workflow

### Step 1: Read the Plan

Read the implementation plan thoroughly. Understand every step, every function signature, every test case before writing any code.

### Step 2: Implement with TDD

For each step in the plan:

1. **Read** every file you're about to modify
2. **Write a failing test** for the step
3. **Run tests** (`<TEST_COMMAND>`) — confirm the new test fails (red)
4. **Write the minimum code** to make the test pass
5. **Run tests** — confirm all tests pass (green)
6. **Refactor** if needed, run tests again
7. Move to the next step

**Lean approach**: write the smallest code that satisfies each requirement. No speculative features, no premature abstractions, no extra comments or docstrings beyond what's in the plan.

### Step 3: Commit Implementation

Once all plan steps are implemented and tests pass, commit:
```
git add <specific files> && git commit -m "feat: implement <task name>"
```
Use a descriptive message. This gives the reviewer a clean diff baseline.

### Step 4: Decision Log

As you implement, maintain a decision log for anything that deviates from or isn't covered by the plan:

- **DEVIATION**: Plan said X but reality required Y. Explain why.
- **AMBIGUITY**: Plan didn't specify how to handle case Z. Explain your choice.
- **SKIP**: Skipped plan step N. Explain why (already handled, unnecessary, etc.).

If the plan is followed exactly with no surprises, the decision log is empty. That's fine.

### Step 5: Dispatch Reviewer

After all plan steps are implemented and tests pass, dispatch an **Opus Reviewer subagent** (model: opus, subagent_type: code-reviewer) with this prompt:

---
You are a critical code reviewer. Review the implementation against the plan using an adversarial mindset — guilty until proven exceptional.

**Methodology**: Use the `critical-code-reviewer` skill for your review methodology. Apply its adversarial lens, detection patterns, and severity tiers to assess the implementation.

## Plan File
Read this: <PLAN_FILE_PATH>

## Spec File
Read this: <SPEC_FILE_PATH>

## Test Command
<TEST_COMMAND>

## Review Criteria (co-created with the user)

Apply these criteria as your evaluation framework:

<REVIEW_CRITERIA>

## Review Process

1. **Run tests first**: Execute `<TEST_COMMAND>`. If tests fail, that's your first and most critical finding. Do not continue the review until you've documented which tests fail and why.

2. **Check the commit log**: Run `git log --oneline` to understand the change history. Use `git diff HEAD~1` to see the latest round's changes, or `git diff <first-implementation-commit>~1..HEAD` for the full diff.

3. **Review against the plan LINE BY LINE**:
   - Did the coder implement every step?
   - Do function signatures, type contracts, and method dispatch match the plan?
   - Are guard conditions, error handling, and API boundary contracts correct?
   - Are there gaps or deviations from the plan?

4. **Code quality** (apply critical-code-reviewer methodology — adversarial, thorough):
   - Clean, minimal, no dead code, no over-engineering?
   - Convention compliance (naming, patterns, style)?
   - Any risks to existing functionality?
   - Data flow correct? (inputs flow to outputs correctly, state mutations are intentional and safe)
   - Regression risks? (does code break existing behavior?)

5. **Test quality**:
   - Are tests meaningful? Do they test behavior, not implementation details?
   - Do they cover the edge cases listed in the plan?
   - Are tests sensitive to breaking changes? (would they catch a regression?)

6. **Evaluate against EACH review criterion** — flag gaps explicitly

## Output

Use severity tiers:
- **BLOCKING**: Must fix before merge. Incorrect logic, failing tests, wrong API contracts.
- **REQUIRED**: Significant issues. Convention violations, missing edge cases, incomplete contracts.
- **SUGGESTION**: Improvements. Better naming, cleaner structure, additional test cases.

For each issue:
- **Severity**: BLOCKING / REQUIRED / SUGGESTION
- **File:line**: where the issue is
- **Problem**: what's wrong
- **Fix**: specific, actionable fix

End with verdict: **LGTM** or **NEEDS FIXES** (list which BLOCKING and REQUIRED issues must be fixed)
---

### Step 6: Fix Loop

If the reviewer says **NEEDS FIXES**:
1. Read the review carefully
2. Apply ALL BLOCKING and REQUIRED fixes (you wrote the code — you understand the reasoning)
3. Run `<TEST_COMMAND>` to confirm tests still pass
4. Commit the fixes: `git commit -am "fix: address review round N feedback"`
5. Add any new decisions to the decision log
6. Dispatch the reviewer again, adding: "This is review round N. Verify previous fixes — use `git diff HEAD~1` to see just this round's changes. Look for NEW issues introduced by the fixes."
7. Repeat until **LGTM** or 3 review rounds

If not LGTM after 3 rounds, note remaining issues in your report.

### Step 7: Report

Report back with EXACTLY this format:

## Status: done / stuck (with reason)

## Files Created
- path/to/new_file

## Files Modified
- path/to/existing_file

## Tests
- X tests passing, Y new tests added
- Test command: <what you ran>

## Review
- Rounds: N
- Final verdict: LGTM / ISSUES REMAINING (count)

## Decision Log
- [DEVIATION] ...
- [AMBIGUITY] ...
(or: No deviations from plan.)
```

### Step 3: Merge (Parallel Mode Only)

When all coder-reviewer agents complete in parallel mode, each returns a worktree branch.

1. For each completed agent, merge its branch into the feature branch:
   ```
   git merge <worktree-branch> --no-edit
   ```
2. If a merge conflict occurs: **stop and report to the orchestrator**. Do NOT auto-resolve merge conflicts. Show which files conflict and between which tasks.
3. After successful merge, clean up the worktree branch:
   ```
   git branch -d <worktree-branch>
   ```
4. Run the full test suite after all merges to catch integration issues.

Skip this step in sequential mode — agents already worked in the same tree.

### Step 4: Verify, Push & PR

1. **Run tests**: Execute the test command on the merged tree. Only check the summary; read full output only on failure.
2. **Check the log**: `git log --oneline` to see the commit history left by agents.
3. **Push**: `git push -u origin <BRANCH_NAME>`
4. **Open PR**: Use `gh pr create` with:
   - Title: concise description of the feature/change
   - Body: the summary table + consolidated decision log (write body first, then create PR)

### Step 5: Report

Return EXACTLY this format to the orchestrator:

```
| Task | Files | Tests | Rounds | Verdict | Decisions |
|------|-------|-------|--------|---------|-----------|
| <name> | <created>/<modified> | <new>/<total> passing | N | LGTM | N deviations |
```

Consolidated decision log (all DEVIATION, AMBIGUITY, SKIP entries across all tasks).

Branch: <branch name>
Commits: <count>
PR: <URL>
````

### Orchestrator During Phase 1

While the sub-orchestrator works:
- Do NOT read code changes or plan details — the sub-orchestrator handles everything
- When the sub-orchestrator returns, relay its summary table, decision log, and PR URL to the user

---

## Rules

- **Plans must exist** — this command implements existing plans, it does not create them
- **Spec file guides implementation** — the spec from `/planning-team` contains validated design decisions and review criteria
- **Review criteria build on the spec** — start from the user-approved criteria in the spec, augmented with skill and plan insights
- **Implementation dispatch is delegated** — a sub-orchestrator manages all coder-reviewer agents; the main orchestrator stays lean
- **One fresh agent per task** — every task gets a NEW Opus coder-reviewer agent with clean context. Never reuse an agent across tasks. The sub-orchestrator dispatches agents, it does NOT implement tasks itself.
- **Coders and reviewers are Opus** — high-effort, maximum quality
- **TDD is non-negotiable** — red → green → refactor, always
- **Lean approach** — smallest code that works, no speculative features
- **Reviewer uses critical-code-reviewer methodology** — adversarial mindset, severity tiers (BLOCKING > REQUIRED > SUGGESTION)
- **Review is iterated** — loop until LGTM, max 3 rounds
- **No review artifacts** — reviews are ephemeral in the agent's context, not saved to disk
- **Decision log is mandatory** — every plan deviation or ambiguity resolution is logged and surfaced
- **Coder self-fixes** — the same agent that wrote the code applies review fixes (has full context)
- **Parallel uses worktrees** — `isolation: "worktree"` on each Task call for true isolation
- **Merge conflicts are human problems** — never auto-resolve, always report
- **Sub-orchestrator verifies** — always run tests before pushing
- **Coders commit their work** — implementation commit + fix commits per review round, giving reviewers clean diffs
- **Sequential preserves tree state** — each coder works in the tree the previous one left
- **Sequential uses fresh agents** — each task gets a NEW agent dispatch via Task tool. Pass prior context (files created, key decisions) in the prompt, not by reusing the same agent.
- **Orchestrator never compacts** — context discipline through delegation, not through reading everything yourself
- **Skills are loaded, not passed** — use `specs-sync load <id>` to hotload skills; never pass absolute file paths to subagents