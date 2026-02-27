# Coercion and Casting with vctrs

### Good - Explicit casting with clear rules

```r
vec_cast(x, double())  # Clear intent, predictable behavior
```

### Good - Common type finding

```r
vec_ptype_common(x, y, z)  # Finds richest compatible type
```

### Avoid - Base R inconsistencies

```r
c(factor("a"), "b")  # Unpredictable behavior
```

### Good - Predictable sizing

```r
vec_c(x, y)  # size = vec_size(x) + vec_size(y)
vec_rbind(df1, df2)  # size = sum of input sizes
```

### Avoid - Unpredictable sizing

```r
c(env_object, function_object)  # Unpredictable length
```
