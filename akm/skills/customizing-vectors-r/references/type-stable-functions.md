# Type-Stable Functions in Packages

### Good - Guaranteed output type

```r
my_function <- function(x, y) {

  result <- x + y
  # Always returns double, regardless of input values
  vec_cast(result, double())
}
```

### Avoid - Type depends on data

```r
bad_function <- function(x) {
  sapply(x, function(i) if(i > 0) 1L else 1.0)
  # Returns integer OR double depending on values!
}
```

### Good - Type assertion at input

```r
safe_function <- function(x) {
  vec_assert(x, double())
  # Now we know x is always double
  x * 2
}
```
