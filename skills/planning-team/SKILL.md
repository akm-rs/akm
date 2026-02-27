---
name: planning-team
description: "Brainstorm with the user, then dispatch Opus planners and reviewers to produce iterated-reviewed implementation plans for one or more tasks."
---

# /planning-team

Brainstorm interactively with the user to produce a validated spec, then dispatch an Opus sub-orchestrator that manages planner-reviewer agents to write detailed implementation plans with iterated review.

## Arguments

- **mode**: `parallel` (default) or `sequential`
  - `parallel`: All plan-writing tasks dispatched simultaneously. Use when tasks are independent.
  - `sequential`: Tasks dispatched one at a time, each as a **separate, fresh agent**. Each receives the previous task's plan as context. Use when tasks depend on each other.

Parse `mode` from `$ARGUMENTS`. If `$ARGUMENTS` contains `sequential`, set mode to sequential. Otherwise default to `parallel`.

## Team Structure

```
Orchestrator (you — stays lean, never compacts)
│
├── Phase 0: Context Gathering
│   ├── Explore subagent → reads source files + project docs
│   └── Skill Discovery → specs-sync search + load
│
├── Phase 1: Brainstorming (you + user, interactive)
│   ├── Ask questions one at a time
│   ├── Present design in sections, validate each
│   ├── Co-create review criteria with user
│   ├── Save spec file to ARTIFACTS_DIR
│   └── Output: spec file path + task list
│
└── Phase 2: Delegate to Planning Dispatch Sub-Orchestrator
    └── Opus sub-orchestrator (single Task agent)
        ├── Reads spec file
        ├── Dispatches one NEW Opus Planner-Reviewer agent PER task
        │   ├── Reads spec + source files, writes plan
        │   ├── Dispatches Opus Reviewer (critical-code-reviewer methodology)
        │   ├── Applies fixes, loops until READY (max 3 rounds)
        │   └── Reports status
        ├── Collects results
        └── Returns summary table to you
```

## Your Role (Orchestrator)

You are the orchestrator. Your job is:

1. **Gather context** — dispatch Explore subagent, read project docs, discover and load relevant skills
2. **Brainstorm with the user** — interactive design session producing a validated spec, review criteria, and task list
3. **Save the spec** — write it to ARTIFACTS_DIR as the single source of truth
4. **Delegate plan dispatch** — hand off to a sub-orchestrator agent that manages all planner-reviewer agents
5. **Present results** — relay the sub-orchestrator's summary to the user

**Context discipline**: After Phase 1, you delegate ALL plan-related work. You never read plan contents. Your context stays lean: brainstorming conversation + spec file path + summary from sub-orchestrator.

---

## Phase 0: Context Gathering

Before engaging the user:

1. Read project docs (CLAUDE.md, AGENTS.md, README) for conventions and structure
2. Dispatch an **Explore subagent** (`subagent_type: Explore`) to read source files relevant to the user's prompt
3. Identify the artifacts directory: `~/.artifacts/<project>/plans/` or the project's designated plans folder
4. **Discover relevant skills**: Run `specs-sync search <terms>` (using terms from the project's stack, frameworks, domain) to find skills that provide expertise for this project's technology. For each relevant skill, run `specs-sync load <id>` to hotload it into the current session. Then read the loaded skills to understand patterns, idioms, and common pitfalls — this knowledge informs review criteria synthesis in Phase 1.

**Do NOT**: record absolute file paths, pass skill paths to subagents, or use any `specs-sync` subcommand other than `search`, `list`, `load`, `unload`, `loaded`, and `status`.

---

## Phase 1: Brainstorming (Interactive)

**Goal**: Produce a validated spec, review criteria, and task list. ALL design decisions are made HERE, not by the planner.

**This phase is non-negotiable. It always happens before any plan dispatch.**

### Process

1. **Present understanding** — briefly summarize what the Explore subagent found and your initial read of the task
2. **Ask questions one at a time** — clarify design decisions, scope, constraints, naming
   - Prefer multiple choice when possible
   - ONE question per message — never batch questions
   - Focus on: purpose, composition model, naming conventions, scope boundaries, edge cases
3. **Explore approaches** — when a design fork appears, propose 2-3 options with trade-offs. Lead with your recommendation and explain why.
4. **Present design in sections** — 200-300 words each. After each section, ask the user if it looks right before continuing.
5. **Produce the validated spec** — a concise summary capturing:
   - Tasks identified (may be 1 or many — brainstorming may reveal decomposition)
   - Per task: what to build, data flow, naming, design decisions made + rationale
   - Source files each planner needs to read
   - Shared conventions and constraints

6. **Co-create review criteria with the user** — this is a MANDATORY, EXPLICIT step. Do NOT skip it. Do NOT synthesize criteria silently. Present a numbered list derived from three sources:
   - **Loaded skills**: What patterns, idioms, and pitfalls do the loaded skills highlight for this stack? What does "good" look like according to the expertise available?
   - **Project docs**: What conventions, priorities, architectural constraints, and testing strategies does the project mandate?
   - **Brainstorming context**: What did the user emphasize? What scope decisions create risk? What areas need extra scrutiny?

   Present the criteria explicitly: "Here are the review criteria I'll hold the plans to — does this cover what matters to you?" Wait for the user to validate, adjust, or add criteria. Iterate until confirmed. These criteria become part of the spec.

### Save the Spec

**After the user confirms both the spec AND the review criteria**, save the full document to:

`<ARTIFACTS_DIR>/<date>-<slug>-spec.md`

The spec file MUST contain:
- All design decisions and rationale from brainstorming
- Task list with descriptions
- Source files per task
- Shared conventions and constraints
- The validated review criteria (numbered list)

This file is the **single source of truth** for all downstream agents. Tell the user the file path.

**Exit criteria**: User explicitly confirms the spec AND review criteria are correct. Spec file is saved to ARTIFACTS_DIR. No ambiguity in scope, approach, or evaluation standards.

### YAGNI

During brainstorming, actively push back on unnecessary complexity. Remove features that aren't clearly needed. The best plans are lean.

---

## Phase 2: Delegate to Planning Dispatch Sub-Orchestrator

After the spec is saved, dispatch a **single Opus sub-orchestrator** (`model: opus`, `subagent_type: general-purpose`) that manages all plan-review work.

This delegation keeps your context lean. You do NOT read plans, manage review rounds, or track individual planner agents. The sub-orchestrator handles everything and returns a summary.

### Sub-Orchestrator Prompt Template

````
You are a planning dispatch orchestrator. Your job is to dispatch planner-reviewer agents for each task in the spec, collect their results, and report a summary.

## Spec File

Read this file FIRST — it contains all design decisions, task descriptions, source files, and review criteria:
<SPEC_FILE_PATH>

## Mode: <parallel|sequential>

## Artifacts Directory

<ARTIFACTS_DIR>

## Project Conventions

<SUMMARY from CLAUDE.md / AGENTS.md — style, patterns, naming, frameworks>

## Your Workflow

### Step 1: Read the Spec

Read the spec file thoroughly. Extract:
- The task list (each task you will dispatch a planner-reviewer for)
- The review criteria (these get injected into every planner and reviewer prompt)
- The source files per task
- Shared conventions and constraints

### Step 2: Dispatch Planner-Reviewer Agents

You will dispatch exactly **one NEW Task subagent per task** (`model: opus`, `subagent_type: general-purpose`). Each subagent runs the full plan-review cycle for its assigned task ONLY. Each agent gets a fresh context — this is critical for plan quality.

**If mode is `parallel`**: Dispatch ALL task agents in a **single response** using parallel Task tool calls. Each agent works independently.

**If mode is `sequential`**: For EACH task, in order:
  1. Dispatch ONE new Task subagent with the task-specific prompt below
  2. Wait for it to complete and report back with status, plan path, review verdict
  3. Note the completed plan file path for context
  4. Dispatch a NEW Task subagent for the next task, passing the previous task's plan file path as "Prior work"

**CRITICAL — BOTH MODES**: You dispatch a **separate, fresh agent** for each task. You do NOT write plans yourself. You do NOT ask a single agent to write multiple plans. Each agent gets ONE task, writes its plan, gets it reviewed, and reports back. This ensures each agent has a clean, focused context.

#### Sequential Dispatch Example

For sequential mode with 3 tasks, you do this:

```
# Task 1 — dispatch NEW agent
Task(prompt="You are a planner-reviewer agent... Task: Task 1 ...", model=opus)
→ Wait for completion → receive report (plan file path, verdict)

# Task 2 — dispatch NEW agent (fresh context)
Task(prompt="You are a planner-reviewer agent... Task: Task 2 ...
  Prior work: Task 1 plan at /path/to/task-1-plan.md ...", model=opus)
→ Wait for completion → receive report

# Task 3 — dispatch NEW agent (fresh context)
Task(prompt="You are a planner-reviewer agent... Task: Task 3 ...
  Prior work: Task 1 plan at /path/to/task-1-plan.md,
              Task 2 plan at /path/to/task-2-plan.md ...", model=opus)
→ Wait for completion → receive report

# All done — report to orchestrator
```

Each dispatch is a NEW independent agent. You NEVER write multiple plans inside a single agent.

#### Planner-Reviewer Agent Prompt

```
You are a planner-reviewer agent. Write a detailed implementation plan for ONE task, get it reviewed against the source code, and iterate until the reviewer approves.

**SCOPE**: You will write a plan for ONLY the task named "<TASK_NAME>" below. You will NOT write plans for any other tasks. When you have completed this ONE plan (reviewer approves), report back with your status. The orchestrator will dispatch a separate agent for the next task.

## Task: <TASK_NAME>

<TASK_DESCRIPTION from spec — include ALL design decisions, naming conventions, scope, rationale>

## Spec File

Read this file for the full validated spec (all design decisions, constraints, and review criteria agreed with the user):
<SPEC_FILE_PATH>

## Review Criteria

The following criteria were co-created with the user. The reviewer will evaluate your plan against them.

<REVIEW_CRITERIA from spec>

## Source Files to Read

You MUST read ALL of these files before writing the plan:
<LIST_OF_FILE_PATHS from spec>

## Project Conventions

<CONVENTIONS>

## Artifacts Directory

<ARTIFACTS_DIR>

## Prior Work (sequential mode only)

<PRIOR_PLAN_PATHS — file paths of plans written by previous agents. Read these for context on what was already planned. Empty for the first task.>

## Your Workflow

### Step 1: Read Source Files

Read EVERY file listed above. Understand the current code before writing anything.

### Step 2: Write the Plan

Write a detailed implementation plan to:
`<ARTIFACTS_DIR>/<date>-<task-slug>-plan.md`

The plan MUST include:
- Complete function signatures with FULL code bodies (not skeletons or pseudocode)
- Explicit type contracts, method dispatch, guard conditions at API boundaries
- Pipeline wiring changes (how new code connects to existing code)
- Testing strategy with concrete test cases (reference the test command documented in project CLAUDE.md or AGENTS.md; never assume language-specific commands)
- Edge cases section
- Exit criteria / definition of done

The plan should be detailed enough that implementation is near copy-paste trivial.

### Step 3: Dispatch Reviewer

Dispatch a **Task subagent** (model: opus, subagent_type: code-reviewer) with this prompt:

---
You are a critical plan reviewer. Review the implementation plan against the actual source code using an adversarial mindset — guilty until proven exceptional.

**Methodology**: Use the `critical-code-reviewer` skill for your review methodology. Apply its adversarial lens, detection patterns, and severity tiers to assess the plan's proposed code.

## Plan File
Read this file: <PLAN_FILE_PATH>

## Spec File (what was agreed with the user)
Read this file: <SPEC_FILE_PATH>

## Review Criteria (co-created with the user)

Apply these criteria as your evaluation framework:

<REVIEW_CRITERIA>

## Source Files to Read (you MUST read these independently — do NOT trust the plan's claims about them)
<SAME FILE LIST AS PLANNER>

## Review Methodology

Apply the critical-code-reviewer approach: adversarial, thorough, zero tolerance for hand-waving.

1. Compare proposed function code against actual source code LINE BY LINE
2. Check every type contract, method dispatch, guard condition against actual code structures
3. Verify data flow: does each step's output match the next step's expected input?
4. Check for behavioral regressions: does the proposed code produce identical results to current code?
5. Verify API boundary contracts are correctly stated
6. Look for missing edge cases
7. Check convention compliance (naming, patterns, style)
8. Evaluate against EACH review criterion above — flag gaps explicitly

## Output Format

Use severity tiers:
- **BLOCKING**: Must fix before plan can proceed. Incorrect logic, wrong API contracts, missing critical steps.
- **REQUIRED**: Significant issues. Convention violations, missing edge cases, incomplete type contracts.
- **SUGGESTION**: Improvements. Better naming, cleaner structure, additional test cases.

For each issue:
- **Severity**: BLOCKING / REQUIRED / SUGGESTION
- **Location**: plan section + source file:line reference
- **Problem**: what's wrong
- **Fix**: specific suggested fix

End with verdict: **READY** or **NEEDS FIXES** (list which BLOCKING and REQUIRED issues must be fixed)
---

### Step 4: Apply Fixes

If the reviewer says **NEEDS FIXES**:
1. Read the review carefully
2. Apply ALL BLOCKING and REQUIRED fixes to the plan file (you wrote the plan — you understand the reasoning behind each decision, so you can apply fixes intelligently, not mechanically)
3. Go back to Step 3 — dispatch the reviewer again, adding to its prompt: "This is review round N. Verify previous fixes are correctly applied. Also look for NEW issues that the fixes may have introduced."
4. Repeat until the reviewer says **READY** or you reach 3 review rounds

If not READY after 3 rounds, add a `## Known Issues` section to the plan with remaining items.

### Step 5: Save Final Review

Write the final review to: `<ARTIFACTS_DIR>/<date>-<task-slug>-review.md`

### Step 6: Report

Report back with EXACTLY this format:
- Status: done / stuck (with reason)
- Plan file: <path>
- Review file: <path>
- Review rounds: N
- Final verdict: READY / ISSUES REMAINING (count)
```

### Step 3: Collect Results

Wait for all planner-reviewer agents to complete. Track progress.

### Step 4: Report

Return EXACTLY this format to the orchestrator:

```
| Task | Plan | Review | Rounds | Verdict |
|------|------|--------|--------|---------|
| <name> | <path> | <path> | N | Ready / Issues |
```

Plus: total artifact count, any tasks needing human attention, and suggested next steps.
````

### Orchestrator During Phase 2

While the sub-orchestrator works:
- Do NOT read the plans or reviews — the sub-orchestrator handles everything
- When the sub-orchestrator returns, relay its summary table to the user
- Add your own next-step suggestion: "review the plans, then use /implementing-team to execute"

---

## Rules

- **Brainstorming is non-negotiable** — Phase 1 ALWAYS happens before any plan dispatch
- **One question at a time** — never batch questions during brainstorming
- **Review criteria are co-created with the user** — presented explicitly, validated interactively, never silently assumed
- **Spec is saved to ARTIFACTS_DIR** — the file is the single source of truth for all downstream work
- **Plan dispatch is delegated** — a sub-orchestrator manages all planner-reviewer agents; the main orchestrator stays lean
- **One fresh agent per task** — every task gets a NEW Opus planner-reviewer agent with clean context. Never reuse an agent across tasks. The sub-orchestrator dispatches agents, it does NOT write plans itself.
- **Planners and reviewers are Opus** — thorough reasoning required
- **Planner revises its own plan** — it has the context of WHY each decision was made
- **Reviewer MUST read source code independently** — not just the plan
- **Reviewer uses critical-code-reviewer methodology** — adversarial mindset, severity tiers (BLOCKING > REQUIRED > SUGGESTION)
- **Review is iterated** — loop until READY, max 3 rounds
- **LINE BY LINE is the standard** — the reviewer compares proposed code against actual source
- **Orchestrator never compacts** — context discipline through delegation, not through reading everything yourself
- **Final review persisted** — saved to disk alongside the plan for traceability
- **Artifacts are permanent** — written to `~/.artifacts/<project>/plans/`, never ephemeral
- **Sequential uses fresh agents** — each task gets a NEW agent dispatch via Task tool. Pass prior plan paths in the prompt, not by reusing the same agent.
- **Never start implementing** — this command produces plans only
- **Skills are loaded, not passed** — use `specs-sync load <id>` to hotload skills; never pass absolute file paths to subagents