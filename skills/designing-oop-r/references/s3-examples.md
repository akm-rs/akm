# S3: Simple Classes

### Constructor function

```r
new_simple <- function(x, label = "") {
  structure(
    x,
    label = label,
    class = "simple"
  )
}
```

### Print method

```r
print.simple <- function(x, ...) {
  label <- attr(x, "label")
  if (nzchar(label)) {
    cat(label, ": ", sep = "")
  }
  cat("Simple(", x, ")\n", sep = "")
  invisible(x)
}
```

### Format method

```r
format.simple <- function(x, ...) {
  paste0("Simple(", x, ")")
}
```

### Usage

```r
s <- new_simple(42, label = "Answer")
print(s)  # "Answer: Simple(42)"
```

### S3 dispatch

```r
summary.simple <- function(object, ...) {
  cat("A simple object with value:", object, "\n")
  cat("Label:", attr(object, "label"), "\n")
}
```
