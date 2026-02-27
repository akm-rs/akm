# Dependency Decision Examples

### Worth adding dependency

```r
# stringr - string manipulation is complex
str_detect(x, "pattern")    # Worth stringr dependency

# lubridate - date parsing is complex
parse_dates(x)              # Worth lubridate dependency
```

### Don't need dependency

```r
# Simple operations don't need purrr
length(x) > 0               # Don't need purrr for this

# Basic math doesn't need dplyr
x + 1                       # Don't need dplyr for this
```

## Tidyverse Dependency Guidelines

**Core tidyverse (usually worth it):**
- dplyr - Complex data manipulation
- purrr - Functional programming, parallel
- stringr - String manipulation
- tidyr - Data reshaping

**Specialized tidyverse (evaluate carefully):**
- lubridate - If heavy date manipulation
- forcats - If many categorical operations
- readr - If specific file reading needs
- ggplot2 - If package creates visualizations

**Heavy dependencies (use sparingly):**
- tidyverse - Meta-package, very heavy
- shiny - Only for interactive apps
