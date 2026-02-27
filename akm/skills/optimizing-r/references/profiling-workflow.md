# Step-by-Step Performance Workflow

### 1. Profile first - find the actual bottlenecks

```r
library(profvis)
profvis({
  # Your slow code here
})
```

### 2. Focus on the slowest parts (80/20 rule)

Don't optimize until you know where time is spent.

### 3. Benchmark alternatives for hot spots

```r
library(bench)
bench::mark(
  current = current_approach(data),
  vectorized = vectorized_approach(data),
  parallel = map(data, in_parallel(func))
)
```

### 4. Consider tool trade-offs based on bottleneck type
