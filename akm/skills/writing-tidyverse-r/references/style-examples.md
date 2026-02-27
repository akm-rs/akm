# Style Guide Examples

## Object naming

### Good

```r
day_one
calculate_mean
user_data
```

### Avoid

```r
DayOne
calculate.mean
userData
```

## Spacing

### Good spacing

```r
x[, 1]
mean(x, na.rm = TRUE)
if (condition) {
  action()
}
```

### Pipe formatting

```r
data |>
  filter(year >= 2020) |>
  group_by(category) |>
  summarise(
    mean_value = mean(value),
    count = n()
  )
```

## Function structure

### Good function structure

```r
rescale01 <- function(x) {
  rng <- range(x, na.rm = TRUE, finite = TRUE)
  (x - rng[1]) / (rng[2] - rng[1])
}
```

### Good naming: snake_case for variables/functions

```r
calculate_mean_score <- function(data, score_col) {
  # Function body
}
```

### Prefix non-standard arguments with .

```r
my_function <- function(.data, ...) {
  # Reduces argument conflicts
}
```
