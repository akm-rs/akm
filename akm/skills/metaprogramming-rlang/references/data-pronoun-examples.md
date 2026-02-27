# Names Patterns with .data

Use .data pronoun for programmatic column access.

### Single column by name

```r
my_mean <- function(data, var) {
  data |> dplyr::summarise(mean = mean(.data[[var]]))
}
```

### Usage - completely insulated from data-masking

```r
mtcars |> my_mean("cyl")  # No ambiguity, works like regular function
```

### Multiple columns with all_of()

```r
my_select_vars <- function(data, vars) {
  data |> dplyr::select(all_of(vars))
}

mtcars |> my_select_vars(c("cyl", "am"))
```
