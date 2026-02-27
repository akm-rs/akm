# Performance Anti-Patterns to Avoid

## Don't optimize without measuring

- Bad: "This looks slow" -> immediately rewrite
- Good: Profile first, optimize bottlenecks

## Don't over-engineer for performance

- Bad: Complex optimizations for 1% gains
- Good: Focus on algorithmic improvements

## Don't assume - measure

- Bad: "for loops are always slow in R"
- Good: Benchmark your specific use case

## Don't ignore readability costs

- Bad: Unreadable code for minor speedups
- Good: Readable code with targeted optimizations

## Growing objects in loops - AVOID

### Bad - Growing objects in loops

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
