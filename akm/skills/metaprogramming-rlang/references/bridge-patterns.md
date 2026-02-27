# Bridge Patterns

Converting between data-masking and tidy selection behaviors.

### across() as selection-to-data-mask bridge

```r
my_group_by <- function(data, vars) {
  data |> dplyr::group_by(across({{ vars }}))
}

# Works with tidy selection
mtcars |> my_group_by(starts_with("c"))
```

### across(all_of()) as names-to-data-mask bridge

```r
my_group_by <- function(data, vars) {
  data |> dplyr::group_by(across(all_of(vars)))
}

mtcars |> my_group_by(c("cyl", "am"))
```
