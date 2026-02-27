# Modern Grouping and Column Operations (dplyr 1.1+)

### Good - Per-operation grouping (always returns ungrouped)

```r
data |>
  summarise(mean_value = mean(value), .by = category)
```

### Good - Multiple grouping variables

```r
data |>
  summarise(total = sum(revenue), .by = c(company, year))
```

### Good - pick() for column selection

```r
data |>
  summarise(
    n_x_cols = ncol(pick(starts_with("x"))),
    n_y_cols = ncol(pick(starts_with("y")))
  )
```

### Good - across() for applying functions

```r
data |>
  summarise(across(where(is.numeric), mean, .names = "mean_{.col}"), .by = group)
```

### Good - reframe() for multi-row results

```r
data |>
  reframe(quantiles = quantile(x, c(0.25, 0.5, 0.75)), .by = group)
```

### Avoid - Old persistent grouping pattern

```r
data |>
  group_by(category) |>
  summarise(mean_value = mean(value)) |>
  ungroup()
```
