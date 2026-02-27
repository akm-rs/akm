---
name: adr-writing
description: Write Architecture Decision Records (ADRs) for any project. Use when evaluating technology choices, architectural changes, or significant design decisions. Covers research phase, human+LLM cost framing, structure, and evidence standards.
---

# ADR Writing Skill

This skill guides the production of Architecture Decision Records (ADRs) in a human+LLM workflow. ADRs serve two audiences:

1. **Token-saving memory for future agents** — the ADR captures research findings, evaluated options, and the rationale behind the chosen solution so that future LLM agents can pick up context without re-doing the research.
2. **Human learning reference** — humans in LLM-assisted workflows make many decisions and spend less time in the code or doing the research themselves. ADRs help them navigate the accumulating flow of decisions and their motivations.

Every ADR must be self-contained, cite concrete evidence, and never include time estimates.

## Quick Reference

| When you need to... | Do this | Section |
|---|---|---|
| Start a new ADR | Research first, then copy the template | Phase 1 + ADR Template |
| Research a topic | Dispatch a subagent for deep research | Phase 1: Research |
| Describe effort or cost | Use scope labels (Small/Medium/Large), describe review burden | Rule 1: Never Estimate Time |
| Evaluate a technology | Check against project hard constraints first | Rule 2: Verify Constraints |
| Explain trade-offs | Frame as generation cost vs. validation cost | Rule 3: Human+LLM Lens |
| Support a recommendation | Cite codebase metrics, benchmarks, external sources | Rule 4: Evidence-Based |
| Describe risk | Include LLM-specific risks (drift, hallucination) | Rule 3 + Common Mistakes |

---

## Phase 1: Research Before Writing

**Never write an ADR without research first.** Dispatch a subagent (or do the research yourself) to gather evidence before drafting.

### Research Checklist

1. **Read project docs** — find the repo map, architecture docs, existing ADRs, and any constraints documented in CLAUDE.md or equivalent
2. **Read existing ADRs** — check for precedent, format consistency, and related decisions already made
3. **Read relevant source code** — gather concrete metrics: line counts, component counts, test counts, module structure
4. **Research external technologies** — if evaluating a tool/framework, gather benchmarks, compatibility data, ecosystem maturity, and LLM training data availability
5. **Identify project hard constraints** — every project has non-negotiable constraints (deployment target, privacy model, core dependencies). List them explicitly before evaluating options.

### Why Research First?

In human+LLM workflows, the LLM can generate a plausible-sounding ADR without evidence. This is dangerous — it produces confident-looking analysis that the human may not catch as unsupported. The research phase ensures every claim in the ADR is grounded in actual data.

---

## Rule 1: Never Estimate Time

**This rule is absolute.** Never write hours, days, weeks, or sprints. The human estimates time; the LLM describes scope.

### Scope Labels

- **Small**: Single file, isolated change. Existing test suite validates correctness.
- **Medium**: Multi-file, cross-module. Initial setup is contained; subsequent changes are small and independent.
- **Large**: Rewrite, new subsystem, or test rewrite. Validation and review burden is significant.

### What to Say Instead

Describe the **review burden**, **validation effort**, and **risk surface** — not calendar time. The human decides how long it takes.

```markdown
❌ "This migration will take approximately 2-3 weeks of development effort."

✅ "Scope: Large. Rewrite 17 components, adapt 794 tests. The mechanical
rewriting is straightforward with LLM tooling, but the validation and review
burden is significant — every component needs manual verification that behavior
is preserved."
```

```markdown
❌ "Estimated effort: 4 hours for implementation, 2 hours for testing."

✅ "Scope: Small. Single-file refactor with clear inputs and outputs.
Existing test suite validates correctness."
```

---

## Rule 2: Always Verify Against Project Hard Constraints

Every project has non-negotiable constraints. Before evaluating any option, identify and list them. Every option must be checked against each constraint. If an option violates any constraint, flag it immediately as a **BLOCKER**.

### How to Find Constraints

Look in: CLAUDE.md, README, architecture docs, deployment configs, existing ADRs. Common categories:

- **Deployment model** — static site, serverless, container, etc.
- **Privacy/data model** — where data lives, what leaves the client
- **Core dependencies** — database, runtime, framework that can't change
- **Platform targets** — browsers, mobile, specific environments

### Examples

```markdown
❌ Evaluating a server-side rendering framework for a static-site project
   without mentioning the deployment constraint.

✅ Dedicating a section to verify compatibility: "Svelte is a compiler that
   produces static output. No runtime server is required. The deployment
   target and privacy model are fully preserved."
```

```markdown
❌ "This technology has compelling performance benefits. We should adopt it."

✅ "Critical Blocker: the extension is NOT available for WASM environments.
   Without WASM support, it cannot be used regardless of performance benefits."
```

---

## Rule 3: Frame Costs Through Human+LLM Lens

In human+LLM workflows, code generation is fast; the bottleneck is always review and validation. Frame every cost discussion through three categories:

### Cost Categories

1. **What's cheap** (LLM generates it): mechanical rewrites, boilerplate, test scaffolding, template code, the ADR itself
2. **What's expensive** (human bottleneck): reviewing generated code for correctness, verifying behavioral preservation, learning a new framework well enough to review LLM output, catching subtle regressions
3. **What's risky** (LLM-specific):
   - **Convention drift** — when adopting new patterns, the first LLM-generated code sets conventions for all future LLM work. Getting early patterns wrong propagates.
   - **Hallucination on unfamiliar APIs** — LLMs may generate plausible-looking but incorrect code for newer or less-common APIs. Note whether the evaluated technology has mature LLM training data.
   - **False confidence** — LLMs can write migration plans that look comprehensive but miss subtle integration issues. Distinguish "mechanical" changes (safe to LLM-generate) from "judgment" changes (need human design).

### Examples

```markdown
❌ "The implementation effort is moderate."

✅ "LLM tooling makes the mechanical rewriting fast, but the real cost is
validation: reviewing every migrated component for correctness, verifying test
coverage, and catching subtle behavioral regressions. That review burden falls
entirely on the human."
```

```markdown
❌ "There is some risk of bugs."

✅ "LLM-generated code may drift from idiomatic patterns when there are no
established project conventions to anchor against — the first migrated
components set the tone, and getting those wrong propagates."
```

---

## ADR Template

Based on the [MADR project template](https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-of-the-madr-project) and [Michael Nygard's template](https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-by-michael-nygard). Use this structure for every ADR.

```markdown
# ADR: <Title>

**Status**: <ACCEPTED | REJECTED | DEFERRED | SUPERSEDED> (<brief reason>)
**Date**: <YYYY-MM-DD>
**Deciders**: <who>
**Technical Story**: <one-line context or link to issue/ticket>

---

## Context and Problem Statement
<Background and situation. What triggered this decision?>
<End with an explicit **Question**: to make the decision point clear.>

---

## Decision Drivers
<Bulleted list of factors, ordered by importance.>
<Always include project hard constraints first when relevant.>

---

## Research Findings
<Evidence gathered during the research phase. Benchmarks, codebase metrics,
external source citations. This section makes the ADR self-contained —
future agents should not need to re-research.>

---

## Considered Options

### Option N: <Name>

**Scope**: <Small | Medium | Large>. <What the work involves. What the review burden is.>

**Pros**:
- <bulleted list>

**Cons**:
- <bulleted list, mark blockers with ❌ BLOCKER>

---

## Decision Outcome

**Chosen option: <Option N — Name>**

### Rationale
<Numbered list explaining why>

### When to Reconsider
<Specific, measurable triggers — required for DEFERRED decisions.
Not "when it makes sense" but "when X observable condition occurs.">

### Implementation Guidance
<Initial direction for the chosen solution — enough for the next agent
to start implementing without re-reading the entire research. This is the
token-saving memory function of the ADR.>

---

## Consequences

### Positive
### Negative
### Neutral

---

## References
<Cited sources with links. Date-stamp information that may evolve.>
```

### Template Rules

- The header metadata (Status, Date, Deciders, Technical Story) is **mandatory**.
- "Context and Problem Statement" must end with an explicit **Question**.
- "Research Findings" captures evidence so future agents don't re-research — this is the ADR's memory function.
- "Considered Options" must evaluate **at least 2 options**.
- Every option needs a **Scope label** (Small/Medium/Large) — never time estimates.
- Blockers are marked with **❌ BLOCKER**.
- "When to Reconsider" is **required** for DEFERRED decisions, with concrete observable triggers.
- "Implementation Guidance" gives the next agent a head start on the chosen path.
- "References" must include **actual links** with dates for information that may evolve.
- Every option has trade-offs — **never write "Cons: None"**.

---

## Rule 4: Evidence-Based Analysis

### Citation Standards

Cite concrete numbers from the codebase. Cite external sources with links.

```markdown
❌ "The codebase is large and complex."

✅ "The codebase has ~11,350 lines of application JS across 59 files,
with 794 passing tests across 38 test files and 17 UI component classes."
```

```markdown
❌ "This format is faster than Parquet."

✅ "18% faster than Parquet V2, 35% faster than Parquet V1 (TPC-H SF100
benchmark) [source](https://example.com/benchmark)"
```

### After-Action Review

For ACCEPTED decisions, note that an after-action review should be conducted after implementation to compare documented expectations with actual practice. This keeps ADRs honest and useful as a learning tool.

---

## Common Mistakes to Prevent

| Mistake | Fix |
|---------|-----|
| Time estimates ("2-3 weeks", "4 hours") | Use scope labels (Small/Medium/Large) + describe review burden |
| Skipping the research phase | Dispatch a subagent or do research yourself before writing |
| Ignoring project hard constraints | Identify constraints from project docs, check every option against them |
| Framing cost as "development effort" | Frame as: generation cost (cheap) vs. validation cost (expensive) vs. LLM risk |
| Vague claims ("it's faster", "it's complex") | Cite benchmarks, codebase metrics, source links |
| Missing "When to Reconsider" on deferred decisions | Add measurable, observable triggers |
| No "Implementation Guidance" section | Include enough direction for the next agent to start without re-researching |
| Recommending without evaluating alternatives | Always present 2+ options with pros/cons |
| Ignoring LLM-specific risks | Address convention drift, hallucination risk, pattern propagation |
| "Cons: None" on the chosen option | Every option has trade-offs; document them honestly |
| Writing the ADR as a one-time artifact | Note when an after-action review should happen |

---

## Further Reading

- [Architecture Decision Records overview](https://github.com/joelparkerhenderson/architecture-decision-record)
- [Suggestions for writing good ADRs](https://github.com/joelparkerhenderson/architecture-decision-record?tab=readme-ov-file#suggestions-for-writing-good-adrs)
- [Simple template (Michael Nygard)](https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-by-michael-nygard)
- [MADR template](https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-of-the-madr-project)
