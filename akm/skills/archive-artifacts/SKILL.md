---
name: archive-artifacts
description: Archive old stale LLM files in the global artifacts folder
---

Review all files in the artifacts (~/.artifacts/<this-repo>) directory. Exclude skills, agents and commands.

For each file, determine if it:

- Describes something fully implemented → move to archive/plans/
- Contains research superseded by newer findings → move to archive/research/
- Is a session note older than 2 weeks → move to archive/sessions/

Commit the moves with a descriptive message listing what was archived and why.

Do NOT archive files that reference ongoing or planned work.
Summarize what you archived and what you kept active.
