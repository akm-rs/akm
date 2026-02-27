# Data Masking and Tidy Selection Examples

Data masking functions: arrange(), filter(), mutate(), summarise()

Tidy selection functions: select(), relocate(), across()

### Function arguments - embrace with {{}}

```r
my_summary <- function(data, group_var, summary_var) {
  data |>
    group_by({{ group_var }}) |>
    summarise(mean_val = mean({{ summary_var }}))
}
```

### Character vectors - use .data[[]]

```r
for (var in names(mtcars)) {
  mtcars |> count(.data[[var]]) |> print()
}
```

### Multiple columns - use across()

```r
data |>
  summarise(across({{ summary_vars }}, ~ mean(.x, na.rm = TRUE)))
```
