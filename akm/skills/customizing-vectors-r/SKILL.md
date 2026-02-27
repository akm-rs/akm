---
name: customizing-vectors-r
description: |
  Type-stable vector operations and custom vector classes using vctrs. Use this skill when building R packages with custom types, need guaranteed output types regardless of input values, implementing consistent coercion/casting rules, or creating vector classes that work seamlessly with data frames. Covers when to use vctrs vs base R, building custom vector classes, coercion methods, and testing vctrs classes.
---

# Customizing Vectors R

This skill covers type-stable operations and custom vector class design using the vctrs package.

## Core Benefits

- **Type stability** - Predictable output types regardless of input values
- **Size stability** - Predictable output sizes from input sizes
- **Consistent coercion rules** - Single set of rules applied everywhere
- **Robust class design** - Proper S3 vector infrastructure

## When to Use vctrs

### Use vctrs when:

1. **Building custom vector classes** - Data frame compatibility, subsetting
2. **Type-stable functions in packages** - Guaranteed output types
3. **Consistent coercion/casting** - Explicit rules, predictable behavior
4. **Size/length stability** - Predictable sizing from inputs

### Don't use vctrs when:

- Simple one-off analyses - Base R is sufficient
- No custom classes needed - Standard types work fine
- Performance critical + simple operations - Base R may be faster
- External API constraints - Must return base R types

## vctrs vs Base R Decision Matrix

| Use Case | Base R | vctrs | When to Choose vctrs |
|----------|--------|-------|---------------------|
| Simple combining | `c()` | `vec_c()` | Need type stability, consistent rules |
| Custom classes | S3 manually | `new_vctr()` | Want data frame compatibility, subsetting |
| Type conversion | `as.*()` | `vec_cast()` | Need explicit, safe casting |
| Finding common type | Not available | `vec_ptype_common()` | Combining heterogeneous inputs |
| Size operations | `length()` | `vec_size()` | Working with non-vector objects |

## Building Custom Vector Classes

See [custom-vector-class.md](references/custom-vector-class.md) for the complete pattern:
- Constructor (low-level)
- Helper (user-facing)
- Format method

## Type-Stable Functions

See [type-stable-functions.md](references/type-stable-functions.md) for:
- Guaranteed output types with `vec_cast()`
- Avoiding type-depends-on-data patterns

## Coercion and Casting

See [coercion-casting.md](references/coercion-casting.md) for:
- Explicit casting with clear rules
- Common type finding with `vec_ptype_common()`
- Self-coercion methods
- Cross-type coercion methods

## Implementation Patterns

### Coercion Methods

Define `vec_ptype2.*` methods for type compatibility:

```r
vec_ptype2.pkg_percent.pkg_percent <- function(x, y, ...) new_percent()
vec_ptype2.pkg_percent.double <- function(x, y, ...) double()
```

### Casting Methods

Define `vec_cast.*` methods for conversion:

```r
vec_cast.pkg_percent.double <- function(x, to, ...) new_percent(x)
vec_cast.double.pkg_percent <- function(x, to, ...) vec_data(x)
```

See [coercion-methods.md](references/coercion-methods.md) for complete examples.

## Performance Considerations

### When vctrs Adds Overhead

- Simple operations - `vec_c(1, 2)` vs `c(1, 2)`
- One-off scripts - Type safety less critical
- Small vectors - Overhead may outweigh benefits

### When vctrs Improves Performance

- Package functions - Type stability prevents expensive re-computation
- Complex classes - Consistent behavior reduces debugging
- Data frame operations - Robust column type handling
- Repeated operations - Predictable types enable optimization

## Package Development

### Exports and Dependencies

```r
# DESCRIPTION
Imports: vctrs

# NAMESPACE - Import what you need
importFrom(vctrs, vec_assert, new_vctr, vec_cast, vec_ptype_common)
```

### Testing vctrs Classes

See [testing-vctrs.md](references/testing-vctrs.md) for:
- Type stability tests
- Coercion tests

## Key Insight

**vctrs is most valuable in package development where type safety, consistency, and extensibility matter more than raw speed for simple operations.**

source: Sarah Johnson's gist https://gist.github.com/sj-io/3828d64d0969f2a0f05297e59e6c15ad
