# Pipe Usage Examples

## Always use native pipe |> instead of magrittr %>%

### Good - Modern native pipe

```r
data |>
  filter(year >= 2020) |>
  summarise(mean_value = mean(value))
```

### Avoid - Legacy magrittr pipe

```r
data %>%
  filter(year >= 2020) %>%
  summarise(mean_value = mean(value))
```
