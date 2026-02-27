---
name: metaprogramming-rlang
description: |
  Tidy evaluation and programmatic tidyverse patterns using rlang. Use this skill when writing functions that accept column names as arguments, building tidyverse-compatible APIs, or working with data-masking and injection operators. Covers embracing with {{}}, injection (!! and !!!), dynamic dots, .data/.env pronouns, name injection with glue syntax, bridge patterns between selection and data-masking, and package development with rlang.
---

# Metaprogramming rlang

This skill covers modern rlang patterns for data-masking, tidy evaluation, and building programmatic tidyverse functions.

## Core Concepts

**Data-masking** allows R expressions to refer to data frame columns as if they were variables in the environment. rlang provides the metaprogramming framework that powers tidyverse data-masking.

### Key rlang Tools

- **Embracing `{{}}`** - Forward function arguments to data-masking functions
- **Injection `!!`** - Inject single expressions or values
- **Splicing `!!!`** - Inject multiple arguments from a list
- **Dynamic dots** - Programmable `...` with injection support
- **Pronouns `.data`/`.env`** - Explicit disambiguation between data and environment variables

## When to Use Each Operator

| Operator | Use Case | Example |
|----------|----------|---------|
| `{{ }}` | Forward function arguments | `summarise(mean = mean({{ var }}))` |
| `!!` | Inject single expression/value | `summarise(mean = mean(!!sym(var)))` |
| `!!!` | Inject multiple arguments | `group_by(!!!syms(vars))` |
| `.data[[]]` | Access columns by name | `mean(.data[[var]])` |

## Function Argument Patterns

### Forwarding with `{{}}`

Use `{{}}` to forward function arguments to data-masking functions. See [embrace-examples.md](references/embrace-examples.md).

### Forwarding `...`

No special syntax needed for dots forwarding. See [dots-forwarding.md](references/dots-forwarding.md).

### Names Patterns with `.data`

Use `.data` pronoun for programmatic column access. See [data-pronoun-examples.md](references/data-pronoun-examples.md).

## Injection Operators

### Advanced Injection with `!!`

Create symbols from strings, inject values to avoid name collisions. See [injection-examples.md](references/injection-examples.md).

### Splicing with `!!!`

Inject multiple symbols from character vectors, splice lists of arguments. See [splicing-examples.md](references/splicing-examples.md).

## Dynamic Dots Patterns

### Using `list2()` for Dynamic Dots Support

Enables splicing, name injection, and trailing commas. See [dynamic-dots-examples.md](references/dynamic-dots-examples.md).

### Name Injection with Glue Syntax

Use glue syntax for dynamic column naming. See [name-injection-examples.md](references/name-injection-examples.md).

## Pronouns for Disambiguation

### `.data` and `.env` Best Practices

Explicit disambiguation prevents masking issues. See [pronouns-examples.md](references/pronouns-examples.md).

## Programming Patterns

### Bridge Patterns

Converting between data-masking and tidy selection behaviors:
- `across()` as selection-to-data-mask bridge
- `across(all_of())` as names-to-data-mask bridge

See [bridge-patterns.md](references/bridge-patterns.md).

### Transformation Patterns

Transform single arguments by wrapping, transform dots with `across()`. See [transformation-patterns.md](references/transformation-patterns.md).

## Error-Prone Patterns to Avoid

### Deprecated/Dangerous Patterns

- String parsing with `eval(parse(text = ...))` - Security risk
- `get()` in data mask - Name collision prone

See [avoid-patterns.md](references/avoid-patterns.md).

### Common Mistakes

- Don't use `{{ }}` on non-arguments
- Don't mix injection styles unnecessarily

## Package Development with rlang

### Import Strategy

```r
# In DESCRIPTION:
Imports: rlang

# In NAMESPACE, import specific functions:
importFrom(rlang, enquo, enquos, expr, !!!, :=)
```

### Documentation Tags

```r
#' @param var <[`data-masked`][dplyr::dplyr_data_masking]> Column to summarize
#' @param ... <[`dynamic-dots`][rlang::dyn-dots]> Additional grouping variables
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Columns to select
```

### Testing rlang Functions

See [testing-examples.md](references/testing-examples.md) for testing data-masking and injection behavior.

source: Sarah Johnson's gist https://gist.github.com/sj-io/3828d64d0969f2a0f05297e59e6c15ad
