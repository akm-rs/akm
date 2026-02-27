# Modern Tidyverse API Design Patterns

### 1. Use .by for per-operation grouping

```r
my_summarise <- function(.data, ..., .by = NULL) {
  .data |>
    dplyr::summarise(..., .by = {{ .by }})
}
```

### 2. Use {{ }} for user-provided columns

```r
my_select <- function(.data, cols) {
  .data |> dplyr::select({{ cols }})
}
```

### 3. Use ... for flexible arguments

```r
my_mutate <- function(.data, ..., .by = NULL) {
  .data |> dplyr::mutate(..., .by = {{ .by }})
}
```

### 4. Return consistent types (tibbles)

```r
my_function <- function(.data) {
  result <- process(.data)
  result |> tibble::as_tibble()
}
```

## Complete example

```r
#' Summarize data with grouping
#'
#' @param .data A data frame
#' @param ... <[`data-masked`][dplyr::dplyr_data_masking]> Summary expressions
#' @param .by <[`tidy-select`][dplyr::dplyr_tidy_select]> Grouping columns
#' @return A tibble
#' @export
my_summary <- function(.data, ..., .by = NULL) {
  .data |>
    dplyr::summarise(..., .by = {{ .by }}) |>
    tibble::as_tibble()
}
```
