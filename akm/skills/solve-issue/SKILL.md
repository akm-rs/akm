---
name: solve-issue
description: "Use when asked to solve a GitHub issue end-to-end."
---

# Solve Issue

Solve GitHub issue **#$ARGUMENTS** from the repo end-to-end using a multi-agent loop. You are the **orchestrator**. You coordinate your planning and implementation teams, using the releant skills. You read context, dispatch subagents, and open the PR.

## Phase 0: Context Gathering (you, the orchestrator)

1. **Detect the repo**: Run `git remote -v` to identify the `owner/repo` for `gh` commands. Use this throughout (never hardcode a repo).
2. **Read the issue**: `gh issue view $ARGUMENTS -R <owner/repo> --json title,body,labels,state`. Save the title and body — you'll need them for the review phase.
3. **Read project context** — AGENTS.md is already in your system prompt. Use it to find whatever project docs exist. Read only what you need to brief the planning agents — don't overload your context.
4. **Detect the tech stack and relevant test commands / programming paradigms**: You'll pass this to subagents.
5. **Detect project conventions**: From AGENTS.md and any architecture docs, note the key conventions (import patterns, naming, test location, etc.).
6. **Create the work branch**: `git checkout -b <feature/fix/docs>/$ARGUMENTS-<short-description>` from the main branch.

Stop here and assess: do you have enough context to brief the agents? If the issue references specific files, read them. Otherwise, move on.

## Phase 1: Planning (dispatch planning subagent)

Invoke **planning-team**. 
Note : After brainstorming with the user and writing the specification, make sure to include the full issue number, title and body to the prompt you send to the planning/reviewer subagents.  

## Phase 2: Implementation (dispatch implementation subagent)

Dispatch an **implementation-team**. 
Note : make sure to include the full issue number, title and body to the prompt you send to the implementation/reviewer subagents.

## Phase 3: Report (you, the orchestrator)

Summarize to the user:

- PR URL
- Summary of the changes made

## Early exit situations

- A branching decision needs to be made and not enough information is available to make it : use your user question tool to ask for clarification / changes.
- Tests are failing and you can't fix them with the information available : inform the user and wait for instructions.
- A missing code dependency / upstream fix needed that eithger wasn't identified or implemented : tell the user to adress this first then come back to this issue.

## Definition of done

- All tests pass
- All issues solved
- All success criterias met
- The plan was followed
- PR open and ready for review by the user