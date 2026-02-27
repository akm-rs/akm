# S7: Modern OOP for New Projects

```r
library(S7)
```

### S7 class definition with properties and validation

```r
Range <- new_class("Range",
  properties = list(
    start = class_double,
    end = class_double
  ),
  validator = function(self) {
    if (self@end < self@start) {
      "@end must be >= @start"
    }
  }
)
```

### Usage - constructor and property access

```r
x <- Range(start = 1, end = 10)
x@start  # 1
x@end <- 20  # automatic validation

# Attempting invalid state triggers error
# x@end <- 0  # Error: @end must be >= @start
```

### Define a generic

```r
inside <- new_generic("inside", "x")
```

### Define a method for Range class

```r
method(inside, Range) <- function(x, y) {
  y >= x@start & y <= x@end
}
```

### Usage

```r
inside(x, 5)   # TRUE
inside(x, 25)  # FALSE
```

## Inheritance

```r
ColoredRange <- new_class("ColoredRange",
  parent = Range,
  properties = list(
    color = class_character
  )
)

cr <- ColoredRange(start = 1, end = 10, color = "red")
cr@color  # "red"
inside(cr, 5)  # TRUE - inherits method from Range
```
