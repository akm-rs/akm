# Testing Patterns

```r
library(testthat)
```

## Unit tests - individual functions

```r
test_that("function handles edge cases", {
  # Empty input
 expect_equal(my_func(c()), expected_empty_result)

  # NULL input errors appropriately
  expect_error(my_func(NULL), class = "my_error_class")

  # NA handling
  expect_equal(my_func(c(1, NA, 3)), expected_na_result)
})

test_that("function validates input", {
  expect_error(my_func("not numeric"), "must be numeric")
  expect_error(my_func(list()), "must be")
})
```

## Integration tests - workflow combinations

```r
test_that("pipeline works end-to-end", {
  result <- data |>
    step1() |>
    step2() |>
    step3()

  expect_s3_class(result, "expected_class")
  expect_true(all(c("col1", "col2") %in% names(result)))
  expect_equal(nrow(result), expected_rows)
})
```

## Property-based tests for package functions

```r
test_that("function properties hold", {
  # Idempotency
  result1 <- normalize(data)
  result2 <- normalize(result1)
  expect_equal(result1, result2)

  # Output shape
  expect_equal(nrow(transform(data)), nrow(data))

  # Type stability
  expect_type(my_func(1:10), "double")
  expect_type(my_func(integer(0)), "double")
})
```

## Snapshot tests for output format

```r
test_that("output format is stable", {
  expect_snapshot(print(my_object))
  expect_snapshot(format(my_object))
})
```
