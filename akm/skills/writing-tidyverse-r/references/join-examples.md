# Modern Join Syntax Examples (dplyr 1.1+)

## Use join_by() instead of character vectors

### Good - Modern join syntax

```r
transactions |>
  inner_join(companies, by = join_by(company == id))
```

### Good - Inequality joins

```r
transactions |>
  inner_join(companies, join_by(company == id, year >= since))
```

### Good - Rolling joins (closest match)

```r
transactions |>
  inner_join(companies, join_by(company == id, closest(year >= since)))
```

### Avoid - Old character vector syntax

```r
transactions |>
  inner_join(companies, by = c("company" = "id"))
```

## Multiple match handling

### Expect 1:1 matches, error on multiple

```r
inner_join(x, y, by = join_by(id), multiple = "error")
```

### Allow multiple matches explicitly

```r
inner_join(x, y, by = join_by(id), multiple = "all")
```

### Ensure all rows match

```r
inner_join(x, y, by = join_by(id), unmatched = "error")
```
