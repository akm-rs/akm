# Internal vs Exported Functions

## Export Function When

- Users will call it directly
- Other packages might want to extend it
- Part of the core package functionality
- Stable API that won't change often

```r
#' Process data with validation
#'
#' Main data processing function for users.
#'
#' @param .data A data frame
#' @param ... Additional arguments
#' @return A processed tibble
#' @export
process_data <- function(.data, ...) {
  # Comprehensive input validation
 if (!is.data.frame(.data)) {
    cli::cli_abort("{.arg .data} must be a data frame.")
  }

  # Call internal helpers
  .data <- .validate_columns(.data)
  .data <- .transform_data(.data, ...)

  tibble::as_tibble(.data)
}
```

## Keep Function Internal When

- Implementation detail that may change
- Only used within package
- Complex implementation helpers
- Would clutter user-facing API

### Internal helper - not exported

Prefix with . to indicate internal.

```r
.validate_columns <- function(.data) {
  # Minimal documentation
  # Can change without breaking users
  # Assume inputs are pre-validated
  required <- c("id", "value")
  missing <- setdiff(required, names(.data))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {.col {missing}}")
  }
  .data
}
```

### Another internal helper

```r
.transform_data <- function(.data, ...) {
  # Implementation details hidden from users
  .data |>
    dplyr::mutate(processed = TRUE)
}
```
