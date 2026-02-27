# Forwarding ... (No Special Syntax Needed)

### Simple dots forwarding

```r
my_group_by <- function(.data, ...) {
  .data |> dplyr::group_by(...)
}
```

### Works with tidy selections too

```r
my_select <- function(.data, ...) {
  .data |> dplyr::select(...)
}
```

### For single-argument tidy selections, wrap in c()

```r
my_pivot_longer <- function(.data, ...) {
  .data |> tidyr::pivot_longer(c(...))
}
```
