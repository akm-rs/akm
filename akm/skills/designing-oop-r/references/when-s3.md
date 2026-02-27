# When to Choose S3

## Simple classes without complex needs

```r
new_simple <- function(x) {
  structure(x, class = "simple")
}

print.simple <- function(x, ...) {
  cat("Simple:", x, "\n")
  invisible(x)
}
```

## Maximum performance needs (rare)

S3 has the lowest overhead of any R OOP system. Only matters in very hot code paths.

## Existing S3 ecosystem contributions

When extending existing S3-based packages. Maintains consistency with ecosystem.

## Quick prototyping

Fast to set up, no dependencies. Can migrate to S7 later if needed.

## Internal classes

Classes only used within a package. Don't need robust external API.
