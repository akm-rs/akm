---
name: designing-oop-r
description: |
  Object-oriented programming in R: S7, S3, S4, and vctrs class design. Use this skill when designing classes for R projects, choosing between OOP systems, building class hierarchies with inheritance, or migrating between systems. Covers S7 class definitions and methods, the decision matrix for choosing S7 vs S3 vs S4 vs vctrs, practical guidelines for each system, and migration strategies.
---

# Designing OOP R

This skill covers object-oriented programming in R, including S7, S3, S4, and vctrs-based classes.

## Decision Tree: What Are You Building?

### 1. Vector-like objects (behave like atomic vectors)

**Use vctrs when:**
- Need data frame integration (columns/rows)
- Want type-stable vector operations
- Building factor-like, date-like, or numeric-like classes
- Need consistent coercion/casting behavior
- Working with existing tidyverse infrastructure

Examples: custom date classes, units, categorical data

### 2. General objects (complex data structures, not vector-like)

**Use S7 when:**
- NEW projects that need formal classes
- Want property validation and safe property access (`@`)
- Need multiple dispatch (beyond S3's double dispatch)
- Converting from S3 and want better structure
- Building class hierarchies with inheritance
- Want better error messages and discoverability

**Use S3 when:**
- Simple classes with minimal structure needs
- Maximum compatibility and minimal dependencies
- Quick prototyping or internal classes
- Contributing to existing S3-based ecosystems
- Performance is absolutely critical (minimal overhead)

**Use S4 when:**
- Working in Bioconductor ecosystem
- Need complex multiple inheritance (S7 doesn't support this)
- Existing S4 codebase that works well

## S7 vs S3 Comparison

| Feature | S3 | S7 | When S7 wins |
|---------|----|----|---------------|
| **Class definition** | Informal (convention) | Formal (`new_class()`) | Need guaranteed structure |
| **Property access** | `$` or `attr()` (unsafe) | `@` (safe, validated) | Property validation matters |
| **Validation** | Manual, inconsistent | Built-in validators | Data integrity important |
| **Method discovery** | Hard to find methods | Clear method printing | Developer experience matters |
| **Multiple dispatch** | Limited (base generics) | Full multiple dispatch | Complex method dispatch needed |
| **Inheritance** | Informal, `NextMethod()` | Explicit `super()` | Predictable inheritance needed |
| **Migration cost** | - | Low (1-2 hours) | Want better structure |
| **Performance** | Fastest | ~Same as S3 | Performance difference negligible |
| **Compatibility** | Full S3 | Full S3 + S7 | Need both old and new patterns |

## S7: Modern OOP

S7 combines S3 simplicity with S4 structure. See [s7-examples.md](references/s7-examples.md) for:
- Class definitions with `new_class()`
- Property validation
- Generic and method definition
- Inheritance with `parent`

## S3: Simple Classes

See [s3-examples.md](references/s3-examples.md) for:
- Constructor functions
- Print and format methods
- Simple class patterns

## Practical Guidelines

### Choose S7 when you have:

See [when-s7.md](references/when-s7.md) for:
- Complex validation needs
- Multiple dispatch needs
- Class hierarchies with clear inheritance

### Choose vctrs when you need:

See [when-vctrs.md](references/when-vctrs.md) for:
- Vector-like behavior in data frames
- Type-stable operations

### Choose S3 when you have:

See [when-s3.md](references/when-s3.md) for:
- Simple classes without complex needs
- Maximum performance needs (rare)
- Existing S3 ecosystem contributions

## Migration Strategy

1. **S3 → S7**: Usually 1-2 hours work, keeps full compatibility
2. **S4 → S7**: More complex, evaluate if S4 features are actually needed
3. **Base R → vctrs**: For vector-like classes, significant benefits
4. **Combining approaches**: S7 classes can use vctrs principles internally

source: Sarah Johnson's gist https://gist.github.com/sj-io/3828d64d0969f2a0f05297e59e6c15ad
