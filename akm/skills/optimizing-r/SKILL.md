---
name: optimizing-r
description: |
  R performance profiling, benchmarking, and optimization strategies. Use this skill when code is running slowly, comparing alternative implementations, deciding between dplyr/data.table/base R, or implementing parallel processing. Covers profvis and bench usage, performance workflow, parallel processing with in_parallel(), data backend selection, modern purrr patterns (list_rbind, walk), and common performance anti-patterns to avoid.
---

# Optimizing R

This skill covers profiling, benchmarking, parallelization, and performance best practices for R.

## Core Principle

**Profile before optimizing** - Use profvis and bench to identify real bottlenecks. Write readable code first, optimize only when necessary.

## Profiling Tools Decision Matrix

| Tool | Use When | Don't Use When | What It Shows |
|------|----------|----------------|---------------|
| **`profvis`** | Complex code, unknown bottlenecks | Simple functions, known issues | Time per line, call stack |
| **`bench::mark()`** | Comparing alternatives | Single approach | Relative performance, memory |
| **`system.time()`** | Quick checks | Detailed analysis | Total runtime only |
| **`Rprof()`** | Base R only environments | When profvis available | Raw profiling data |

## Performance Workflow

1. **Profile first** - Find the actual bottlenecks
2. **Focus on the slowest parts** - 80/20 rule
3. **Benchmark alternatives** - For hot spots only
4. **Consider tool trade-offs** - Based on bottleneck type

See [profiling-workflow.md](references/profiling-workflow.md) for the complete workflow.

## When Each Tool Helps vs Hurts

### Parallel Processing (`in_parallel()`)

**Helps when:**
- CPU-intensive computations
- Embarrassingly parallel problems
- Large datasets with independent operations
- I/O bound operations (file reading, API calls)

**Hurts when:**
- Simple, fast operations (overhead > benefit)
- Memory-intensive operations (may cause thrashing)
- Operations requiring shared state
- Small datasets

See [parallel-examples.md](references/parallel-examples.md) for decision points.

### Data Backend Selection

| Backend | Use When |
|---------|----------|
| **data.table** | Very large datasets (>1GB), complex grouping, maximum performance critical |
| **dplyr** | Readability priority, complex joins/window functions, moderate data (<100MB) |
| **base R** | No dependencies allowed, simple operations, teaching/learning |

See [backend-selection.md](references/backend-selection.md) for guidance.

## Profiling Best Practices

1. **Profile realistic data sizes** - Not toy examples
2. **Profile multiple runs** - For stability
3. **Check memory usage too** - Not just time
4. **Profile realistic usage patterns** - Not isolated calls

See [profiling-best-practices.md](references/profiling-best-practices.md) for examples.

## Performance Anti-Patterns to Avoid

- **Don't optimize without measuring** - Profile first
- **Don't over-engineer** - Complex optimizations for 1% gains
- **Don't assume** - "for loops are always slow" is a myth
- **Don't ignore readability costs** - Readable code with targeted optimizations

See [performance-anti-patterns.md](references/performance-anti-patterns.md) for examples.

## Modern purrr Patterns

### Data Frame Binding (purrr 1.0+)

| Superseded | Modern Replacement |
|------------|-------------------|
| `map_dfr(x, f)` | `map(x, f) \|> list_rbind()` |
| `map_dfc(x, f)` | `map(x, f) \|> list_cbind()` |
| `map2_dfr(x, y, f)` | `map2(x, y, f) \|> list_rbind()` |

### Side Effects with `walk()`

Use `walk()` and `walk2()` for side effects (file writing, plotting).

### Parallel Processing (purrr 1.1.0+)

Use `in_parallel()` with mirai for scaling across cores.

See [purrr-patterns.md](references/purrr-patterns.md) for all patterns.

## Backend Tools for Performance

When speed is critical, consider:
- **vctrs** - Type-stable vector operations
- **rlang** - Metaprogramming
- **data.table** - Large data operations

Profile to identify whether these tools will help your specific bottleneck.

source: Sarah Johnson's gist https://gist.github.com/sj-io/3828d64d0969f2a0f05297e59e6c15ad
