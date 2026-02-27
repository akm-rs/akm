# Input Validation Patterns

## User-facing functions - comprehensive validation

```r
user_function <- function(x, threshold = 0.5) {
  # Check all inputs thoroughly
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop("threshold must be a single number")
  }
  if (threshold < 0 || threshold > 1) {
    stop("threshold must be between 0 and 1")
  }

  # ... function body
  x[x > threshold]
}
```

## Internal functions - minimal validation

```r
.internal_function <- function(x, threshold) {
 # Assume inputs are valid (document assumptions)
  # Only check critical invariants
  stopifnot(length(x) > 0)

  # ... function body
  x[x > threshold]
}
```

## Package functions with vctrs - type-stable validation

```r
safe_function <- function(x, y) {
  # Automatic type checking and coercion
  x <- vctrs::vec_cast(x, double())
  y <- vctrs::vec_cast(y, double())

  # Now we know types are correct
  x + y
}
```
