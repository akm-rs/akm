# Building Custom Vector Classes with vctrs

### Constructor (low-level)

```r
new_percent <- function(x = double()) {
  vec_assert(x, double())
  new_vctr(x, class = "pkg_percent")
}
```

### Helper (user-facing)

```r
percent <- function(x = double()) {
  x <- vec_cast(x, double())
  new_percent(x)
}
```

### Format method

```r
format.pkg_percent <- function(x, ...) {
  paste0(vec_data(x) * 100, "%")
}
```

### Usage

```r
pct <- percent(0.5)
print(pct)  # "50%"

# Automatic data frame compatibility, subsetting, etc.
df <- data.frame(x = 1:3, pct = percent(c(0.1, 0.2, 0.3)))
```
