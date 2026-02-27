# When to Choose vctrs

```r
library(vctrs)
```

## Vector-like behavior in data frames

### Define a percentage class

```r
new_percent <- function(x = double()) {
  vec_assert(x, double())
  new_vctr(x, class = "percentage")
}

percent <- function(x = double()) {
  x <- vec_cast(x, double())
  new_percent(x)
}

format.percentage <- function(x, ...) {
  paste0(vec_data(x) * 100, "%")
}
```

### Works seamlessly in data frames

```r
df <- data.frame(
  x = 1:3,
  pct = percent(c(0.1, 0.2, 0.3))
)
```

## Type-stable operations

### Combining maintains type

```r
vec_c(percent(0.1), percent(0.2))  # predictable behavior
```

### Explicit, safe casting

```r
vec_cast(0.5, percent())  # converts double to percent
```

## When vctrs is the right choice

- Custom date/time classes
- Unit-aware numbers (meters, kilograms)
- Categorical data with custom behavior
- Any "vector-like" data that should work in tidyverse
