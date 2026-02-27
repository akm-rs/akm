# Error Handling Patterns

### Good error messages - specific and actionable

```r
process_data <- function(x) {
  if (length(x) == 0) {
    cli::cli_abort(
      "Input {.arg x} cannot be empty.",
      "i" = "Provide a non-empty vector."
    )
  }

  # ... process
}
```

### Include function name in errors

```r
validate_input <- function(x, call = rlang::caller_env()) {
  if (!is.numeric(x)) {
    cli::cli_abort(
      "Input must be numeric, not {.cls {class(x)}}.",
      call = call
    )
  }
}

my_function <- function(x) {
  validate_input(x)  # Error will point to my_function, not validate_input
  x * 2
}
```

## Error styling guidelines

### Use cli for user-friendly messages

```r
cli::cli_abort("Column {.col name} not found in data.")
cli::cli_warn("NAs introduced by coercion.")
cli::cli_inform("Processing {.val {n}} rows.")
```

### Highlight different elements appropriately

- `{.arg x}` - function arguments
- `{.col name}` - column names
- `{.cls class}` - class names
- `{.val value}` - values
- `{.fn func}` - function names
- `{.file path}` - file paths
