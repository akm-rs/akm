# Anti-Patterns to Avoid

## Legacy Patterns

### Avoid - Old pipe

```r
data %>% function()
```

### Avoid - Old join syntax

```r
inner_join(x, y, by = c("a" = "b"))
```

### Avoid - Implicit type conversion

```r
sapply()  # Use map_*() instead
```

### Avoid - String manipulation in data masking

```r
mutate(data, !!paste0("new_", var) := value)
# Use across() or other approaches instead
```

## Performance Anti-Patterns

### Avoid - Growing objects in loops

```r
result <- c()
for(i in 1:n) {
  result <- c(result, compute(i))  # Slow!
}
```

### Good - Pre-allocate

```r
result <- vector("list", n)
for(i in 1:n) {
  result[[i]] <- compute(i)
}
```

### Better - Use purrr

```r
result <- map(1:n, compute)
```

## Type Stability Anti-Patterns

### Avoid - Type-unstable base functions

```r
sapply(data, mean)     # might return list or vector
```

### Good - Type-stable purrr functions

```r
map_dbl(data, mean)    # always returns double
map_chr(data, class)   # always returns character
```

### Avoid - explicit loops for simple operations

```r
result <- numeric(length(x))
for(i in seq_along(x)) {
  result[i] <- x[i] + y[i]
}
```

### Good - vectorized operations

```r
result <- x + y
```
