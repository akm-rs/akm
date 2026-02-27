# When to Choose S7

```r
library(S7)
```

## Complex validation needs

```r
Range <- new_class("Range",
  properties = list(
    start = class_double,
    end = class_double
  ),
  validator = function(self) {
    if (self@end < self@start) "@end must be >= @start"
  }
)
```

## Multiple dispatch needs

```r
combine <- new_generic("combine", c("x", "y"))

method(combine, list(Range, Range)) <- function(x, y) {
  Range(
    start = min(x@start, y@start),
    end = max(x@end, y@end)
  )
}
```

## Class hierarchies with clear inheritance

```r
Shape <- new_class("Shape",
  properties = list(
    color = class_character
  )
)

Circle <- new_class("Circle",
  parent = Shape,
  properties = list(
    radius = class_double
  )
)

Rectangle <- new_class("Rectangle",
  parent = Shape,
  properties = list(
    width = class_double,
    height = class_double
  )
)
```

### Generic with method for parent

```r
area <- new_generic("area", "x")

method(area, Circle) <- function(x) {
  pi * x@radius^2
}

method(area, Rectangle) <- function(x) {
  x@width * x@height
}
```
