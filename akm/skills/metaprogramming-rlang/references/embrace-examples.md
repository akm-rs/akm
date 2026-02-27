# Forwarding with {{}} (Embrace)

Use {{}} to forward function arguments to data-masking functions.

### Single argument forwarding

```r
my_summarise <- function(data, var) {
  data |> dplyr::summarise(mean = mean({{ var }}))
}
```

### Works with any data-masking expression

```r
mtcars |> my_summarise(cyl)
mtcars |> my_summarise(cyl * am)
mtcars |> my_summarise(.data$cyl)  # pronoun syntax supported
```
