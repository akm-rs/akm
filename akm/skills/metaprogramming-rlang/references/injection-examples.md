# Advanced Injection with !!

### Create symbols from strings

```r
var <- "cyl"
mtcars |> dplyr::summarise(mean = mean(!!sym(var)))
```

### Inject values to avoid name collisions

```r
df <- data.frame(x = 1:3)
x <- 100
df |> dplyr::mutate(scaled = x / !!x)  # Uses both data and env x
```

### Use data_sym() for tidyeval contexts (more robust)

```r
mtcars |> dplyr::summarise(mean = mean(!!data_sym(var)))
```
