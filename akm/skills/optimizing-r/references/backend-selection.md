# Data Backend Selection Guide

## Use data.table when

- Very large datasets (>1GB)
- Complex grouping operations
- Reference semantics desired
- Maximum performance critical

```r
library(data.table)
dt <- as.data.table(large_data)
dt[, .(mean_val = mean(value)), by = group]
```

## Use dplyr when

- Readability and maintainability priority
- Complex joins and window functions
- Team familiarity with tidyverse
- Moderate sized data (<100MB)

```r
library(dplyr)
data |>
  group_by(group) |>
  summarise(mean_val = mean(value))
```

## Use base R when

- No dependencies allowed
- Simple operations
- Teaching/learning contexts

```r
aggregate(value ~ group, data, mean)
```
