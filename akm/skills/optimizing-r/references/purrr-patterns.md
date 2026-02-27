# Modern purrr Patterns (purrr 1.0+)

### Modern data frame row binding

```r
models <- data_splits |>
  map(\(split) train_model(split)) |>
  list_rbind()  # Replaces map_dfr()
```

### Column binding

```r
summaries <- data_list |>
  map(\(df) get_summary_stats(df)) |>
  list_cbind()  # Replaces map_dfc()
```

### Superseded functions migration

```r
# map_dfr(x, f)      -> map(x, f) |> list_rbind()
# map_dfc(x, f)      -> map(x, f) |> list_cbind()
# map2_dfr(x, y, f)  -> map2(x, y, f) |> list_rbind()
# pmap_dfr(list, f)  -> pmap(list, f) |> list_rbind()
# imap_dfr(x, f)     -> imap(x, f) |> list_rbind()
```

### Side effects with walk()

```r
plots <- walk2(data_list, plot_names, \(df, name) {
  p <- ggplot(df, aes(x, y)) + geom_point()
  ggsave(name, p)
})
```

### For side effects - use walk instead of for loops

```r
walk(x, write_file)
walk2(data, paths, write_csv)
```

## Parallel processing (purrr 1.1.0+)

```r
library(mirai)
daemons(4)
results <- large_datasets |>
  map(in_parallel(expensive_computation))
daemons(0)
```
