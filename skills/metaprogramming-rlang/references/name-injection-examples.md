# Name Injection with Glue Syntax

### Basic name injection

```r
name <- "result"
list2("{name}" := 1)  # Creates list(result = 1)
```

### In function arguments with {{

```r
my_mean <- function(data, var) {
  data |> dplyr::summarise("mean_{{ var }}" := mean({{ var }}))
}

mtcars |> my_mean(cyl)        # Creates column "mean_cyl"
mtcars |> my_mean(cyl * am)   # Creates column "mean_cyl * am"
```

### Allow custom names with englue()

```r
my_mean <- function(data, var, name = englue("mean_{{ var }}")) {
  data |> dplyr::summarise("{name}" := mean({{ var }}))
}

# User can override default
mtcars |> my_mean(cyl, name = "cylinder_mean")
```
