# Testing vctrs Classes

### Test type stability

```r
test_that("my_function is type stable", {
  expect_equal(vec_ptype(my_function(1:3)), vec_ptype(double()))
  expect_equal(vec_ptype(my_function(integer())), vec_ptype(double()))
})
```

### Test coercion

```r
test_that("coercion works", {
  expect_equal(vec_ptype_common(new_percent(), 1.0), double())
  expect_error(vec_ptype_common(new_percent(), "a"))
})
```

### Test casting

```r
test_that("casting works", {
  pct <- percent(0.5)
  expect_equal(vec_cast(pct, double()), 0.5)
  expect_equal(vec_cast(0.5, percent()), percent(0.5))
})
```

### Test vector operations

```r
test_that("vector operations work", {
  pct1 <- percent(0.1)
  pct2 <- percent(0.2)
  combined <- vec_c(pct1, pct2)
  expect_s3_class(combined, "pkg_percent")
  expect_equal(vec_size(combined), 2)
})
```
