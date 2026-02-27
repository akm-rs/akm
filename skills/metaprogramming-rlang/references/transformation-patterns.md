# Transformation Patterns

### Transform single arguments by wrapping

```r
my_mean <- function(data, var) {
  data |> dplyr::summarise(mean = mean({{ var }}, na.rm = TRUE))
}
```

### Transform dots with across()

```r
my_means <- function(data, ...) {
  data |> dplyr::summarise(across(c(...), ~ mean(.x, na.rm = TRUE)))
}
```

### Manual transformation (advanced)

```r
my_means_manual <- function(.data, ...) {
  vars <- enquos(..., .named = TRUE)
  vars <- purrr::map(vars, ~ expr(mean(!!.x, na.rm = TRUE)))
  .data |> dplyr::summarise(!!!vars)
}
```
