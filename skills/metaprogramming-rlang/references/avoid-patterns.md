# Error-Prone Patterns to Avoid

## Deprecated/Dangerous Patterns

### Avoid - String parsing and eval (security risk)

```r
var <- "cyl"
code <- paste("mean(", var, ")")
eval(parse(text = code))  # Dangerous!
```

### Good - Symbol creation and injection

```r
!!sym(var)  # Safe symbol injection
```

### Avoid - get() in data mask (name collisions)

```r
with(mtcars, mean(get(var)))  # Collision-prone
```

### Good - Explicit injection or .data

```r
with(mtcars, mean(!!sym(var)))  # Safe
# or
mtcars |> summarise(mean(.data[[var]]))  # Even safer
```

## Common Mistakes

### Don't use {{ }} on non-arguments

```r
my_func <- function(x) {
  x <- force(x)  # x is now a value, not an argument
  quo(mean({{ x }}))  # Wrong! Captures value, not expression
}
```

### Don't mix injection styles unnecessarily

Pick one approach and stick with it:

### Either: embrace pattern

```r
my_func <- function(data, var) data |> summarise(mean = mean({{ var }}))
```

### Or: defuse-and-inject pattern

```r
my_func <- function(data, var) {
  var <- enquo(var)
  data |> summarise(mean = mean(!!var))
}
```
