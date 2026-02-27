# Parallel Processing Decision Points

## Helps when

- CPU-intensive computations
- Embarrassingly parallel problems
- Large datasets with independent operations
- I/O bound operations (file reading, API calls)

## Hurts when

- Simple, fast operations (overhead > benefit)
- Memory-intensive operations (may cause thrashing)
- Operations requiring shared state
- Small datasets

## Example decision point

```r
expensive_func <- function(x) Sys.sleep(0.1) # 100ms per call
fast_func <- function(x) x^2                 # microseconds per call
```

### Good for parallel

```r
library(mirai)
daemons(4)
results <- map(1:100, in_parallel(expensive_func))  # ~10s -> ~2.5s on 4 cores
daemons(0)
```

### Bad for parallel (overhead > benefit)

```r
map(1:100, in_parallel(fast_func))  # 100us -> 50ms (500x slower!)
```

## Use parallel processing with mirai (purrr 1.1.0+)

```r
library(mirai)
daemons(4)
results <- large_datasets |>
  map(in_parallel(expensive_computation))
daemons(0)
```
