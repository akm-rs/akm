---
name: generate-rpkg-consumer-skill
description: Generate a condensed consumer skill for a package/library/tool with an API
---

# generate-rpkg-consumer-skill

Generate a condensed consumer skill package for this R package, suitable for LLM agents helping users integrate this library.
Write it to the root of the repo, and suggest the user move it to .claude / .github or in the global folders.

## Instructions

When this command is invoked, the agent should:

### 1. Analyze the Codebase

Read and understand:
- `DESCRIPTION` file for package metadata
- Main exported functions (check `NAMESPACE` or `@export` tags)
- Entry points (look for primary user-facing functions)
- Data requirements (function parameters, expected formats)
- Error handling and validation code
- Tests for usage examples
- Existing documentation (README, vignettes)

### 2. Generate Skill Structure

Create the following files in the output directory:

#### SKILL.md (~300-500 lines)
The main skill file with:

(NOTE: ACTUALLY MAKE IT A YAML FRONTMATTER, DON'T COPY PASTE THIS BLOCK WITH THE BACKTICKS OR THE SKILL WON'T WORK)

```markdown
# <PackageName> Consumer Skill

## Metadata
```yaml
name: r-<package>-consumer
description: <one-line description focused on when to use the skill, not what it does>
```

## What This Skill Covers
<brief scope statement>

## 1. Conceptual Overview
### What <Package> Does
<2-3 paragraphs explaining the problem and solution>

### Core Data Flow
<diagram or description of input → processing → output>

## 2. API Surface
### Primary Entry Point
<main function signature, parameters table, return value>

### Valid Parameter Values
<tables of valid values for enum-like parameters>

## 3. Data Contracts
<summary of input requirements, link to supplementary file>

## 4. Integration Patterns
<2-3 code patterns for common use cases>

## 5. Gotchas and Invariants
<critical requirements that would cause errors if missed>

## 6. What NOT to Do
<anti-patterns with ❌/✅ examples>

## 7. Error Handling
<common errors and solutions table>

## 8. Supplementary Files
<links to additional documentation>
```

#### data-contracts.md
Detailed specification of all input data requirements:
- Required tables/objects
- Required columns with types
- Valid value ranges
- Coercion rules
- Validation examples

#### examples.md
Complete, runnable code examples for:
- Minimal working example
- Common production patterns
- Edge cases
- Debugging workflows

#### troubleshooting.md
Organized error resolution guide:
- Error messages → causes → solutions
- Performance issues
- Memory issues
- Common mistakes

### 3. Quality Checklist

Before finalizing, verify:
- [ ] All public functions documented
- [ ] All required parameters explained
- [ ] Valid parameter values enumerated
- [ ] Input data format fully specified
- [ ] At least 3 integration patterns shown
- [ ] 5+ gotchas identified
- [ ] 5+ anti-patterns documented
- [ ] Error messages mapped to solutions
- [ ] Examples are runnable (not pseudocode)
- [ ] Code examples use current API (not deprecated)

### 4. Output

After generating files:
1. Report file locations and sizes
2. Summarize key points for user review
3. Suggest any gaps that need human input (e.g., internal-only knowledge)

## Example Invocation

```
/generate-rpkg-consumer-skill
```

## Template for Information Extraction

When analyzing the codebase, collect:

```yaml
package:
  name: <from DESCRIPTION>
  title: <from DESCRIPTION>
  version: <from DESCRIPTION>

entry_points:
  - function: <name>
    signature: <full signature>
    description: <what it does>
    returns: <return type and structure>

parameters:
  - name: <param>
    type: <R type>
    required: <yes/no>
    valid_values: <list or description>
    default: <default value>

input_data:
  - name: <table/object name>
    description: <purpose>
    columns:
      - name: <column>
        type: <type>
        required: <yes/no>
        constraints: <validation rules>

common_errors:
  - message: <error text>
    cause: <why it happens>
    solution: <how to fix>

performance:
  small_data: <guidance>
  large_data: <guidance>
  memory: <limits and configuration>
```

## Notes

- Focus on consumer perspective (using the package), not developer perspective (contributing to it)
- Assume consumer has basic R knowledge but no package internals knowledge
- Prioritize "what will make the LLM get it right on first try"
- Include both R code and SQL patterns if package supports multiple backends
- Test examples mentally for correctness before including
