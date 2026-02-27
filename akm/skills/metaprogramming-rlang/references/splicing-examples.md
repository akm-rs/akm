# Splicing with !!!

### Multiple symbols from character vector

```r
vars <- c("cyl", "am")
mtcars |> dplyr::group_by(!!!syms(vars))
```

### Or use data_syms() for tidy contexts

```r
mtcars |> dplyr::group_by(!!!data_syms(vars))
```

### Splice lists of arguments

```r
args <- list(na.rm = TRUE, trim = 0.1)
mtcars |> dplyr::summarise(mean = mean(cyl, !!!args))
```
