# Profiling Best Practices

### 1. Profile realistic data sizes

```r
library(profvis)
profvis({
  # Use actual data size, not toy examples
  real_data |> your_analysis()
})
```

### 2. Profile multiple runs for stability

```r
library(bench)
bench::mark(
  your_function(data),
  min_iterations = 10,  # Multiple runs
  max_iterations = 100
)
```

### 3. Check memory usage too

```r
bench::mark(
  approach1 = method1(data),
  approach2 = method2(data),
  check = FALSE,  # If outputs differ slightly
  filter_gc = FALSE  # Include GC time
)
```

### 4. Profile with realistic usage patterns

Not just isolated function calls.
