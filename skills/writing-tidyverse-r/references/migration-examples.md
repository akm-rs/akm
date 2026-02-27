# Migration Examples: Base R and Old Tidyverse to Modern Patterns

## Base R to Modern Tidyverse

### Data manipulation

```r
subset(data, condition)          # -> filter(data, condition)
data[order(data$x), ]            # -> arrange(data, x)
aggregate(x ~ y, data, mean)     # -> summarise(data, mean(x), .by = y)
```

### Functional programming

```r
sapply(x, f)                     # -> map(x, f)  # type-stable
lapply(x, f)                     # -> map(x, f)
```

### String manipulation

```r
grepl("pattern", text)           # -> str_detect(text, "pattern")
gsub("old", "new", text)         # -> str_replace_all(text, "old", "new")
substr(text, 1, 5)               # -> str_sub(text, 1, 5)
nchar(text)                      # -> str_length(text)
strsplit(text, ",")              # -> str_split(text, ",")
paste0(a, b)                     # -> str_c(a, b)
tolower(text)                    # -> str_to_lower(text)
```

## Old to New Tidyverse Patterns

### Pipes

```r
data %>% function()              # -> data |> function()
```

### Grouping (dplyr 1.1+)

```r
group_by(data, x) |>
  summarise(mean(y)) |>
  ungroup()                      # -> summarise(data, mean(y), .by = x)
```

### Column selection

```r
across(starts_with("x"))         # -> pick(starts_with("x"))  # for selection only
```

### Joins

```r
by = c("a" = "b")                # -> by = join_by(a == b)
```

### Multi-row summaries

```r
summarise(data, x, .groups = "drop") # -> reframe(data, x)
```

### Data reshaping

```r
gather()/spread()                # -> pivot_longer()/pivot_wider()
```

### String separation (tidyr 1.3+)

```r
separate(col, into = c("a", "b"))
# -> separate_wider_delim(col, delim = "_", names = c("a", "b"))

extract(col, into = "x", regex)
# -> separate_wider_regex(col, patterns = c(x = regex))
```

### Superseded purrr functions (purrr 1.0+)

```r
map_dfr(x, f)                    # -> map(x, f) |> list_rbind()
map_dfc(x, f)                    # -> map(x, f) |> list_cbind()
map2_dfr(x, y, f)                # -> map2(x, y, f) |> list_rbind()
pmap_dfr(list, f)                # -> pmap(list, f) |> list_rbind()
imap_dfr(x, f)                   # -> imap(x, f) |> list_rbind()
```

### For side effects

```r
walk(x, write_file)              # instead of for loops
walk2(data, paths, write_csv)    # multiple arguments
```
