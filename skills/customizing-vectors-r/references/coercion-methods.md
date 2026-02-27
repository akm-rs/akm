# Coercion Methods for Custom Classes

### Self-coercion (same type to same type)

```r
vec_ptype2.pkg_percent.pkg_percent <- function(x, y, ...) {
  new_percent()
}
```

### With double - percent + double = double

```r
vec_ptype2.pkg_percent.double <- function(x, y, ...) double()
vec_ptype2.double.pkg_percent <- function(x, y, ...) double()
```

### Casting - converting between types

```r
vec_cast.pkg_percent.double <- function(x, to, ...) {
  new_percent(x)
}
vec_cast.double.pkg_percent <- function(x, to, ...) {
  vec_data(x)
}
```

### Usage examples

```r
pct <- percent(0.5)
vec_c(pct, pct)           # Returns percent
vec_c(pct, 0.3)           # Returns double (common type)
vec_cast(0.75, percent()) # Converts double to percent
```
