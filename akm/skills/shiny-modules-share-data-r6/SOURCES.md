# Sources

This skill is based on (and cites) *Engineering Production-Grade Shiny Apps* (online edition):

- Engineering Shiny (book home): https://engineering-shiny.org/
- Structuring projects → “Communication between modules”: https://engineering-shiny.org/structuring-project.html#communication-between-modules
- Common app caveats → “Using R6 as data storage”: https://engineering-shiny.org/common-app-caveats.html#using-r6-as-data-storage
- Appendix A (minifying app) → Step 4 “Strengthen”: https://engineering-shiny.org/appendix-a---use-case-building-an-app-from-start-to-finish.html#step-4-strengthen-1

Practical reference implementation (R6 object passed to modules) used as inspiration:

- `minifying` repo, step-4-strengthen: https://github.com/ColinFay/minifying/tree/master/step-4-strengthen
  - In particular: `step-4-strengthen/R/fct_R6.R` (R6 class) and `step-4-strengthen/R/mod_left.R`, `step-4-strengthen/R/mod_right.R` (modules consuming the shared R6 object).
