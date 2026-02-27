---
name: shiny-modules-share-data-r6
description: |
  Use when multiple modules need to **read and write** shared state (e.g reactiveValues), when you want to avoid “long reactive chains” (module A returns a reactive to parent, parent passes to B, etc.), or when you need **encapsulation**: methods like `state$set_x()` / `state$compute()` rather than exposing raw `reactiveValues()` everywhere.
---

# Name
shiny-modules-share-data

# Goal
Help users share state across multiple `{shiny}` modules in a controlled way by passing a single **R6 “data storage” object** (a mutable store) to modules.

# When to use / when not to use

## Use when
- Multiple modules need to **read and write** shared state (e.g., current dataset, filters, selected record, computed results).
- You want to avoid “long reactive chains” (module A returns a reactive to parent, parent passes to B, etc.) and keep the app wiring simpler.
- You need **encapsulation**: methods like `state$set_x()` / `state$compute()` rather than exposing raw `reactiveValues()` everywhere.

## Don’t use when
- State is truly local to a module (keep it inside the module).
- You only need one-way data flow (a simple `reactive()`/`reactiveVal()` return from a module may be enough).
- You store *non-reactive* values inside the R6 and expect Shiny outputs to update automatically (they won’t).

# Inputs
- A Shiny app that uses modules.
- A design decision about what should be shared as **reactive fields**.

# Outputs
- A pattern and template code for:
  - An R6 `AppState` object
  - Passing the object into modules
  - Reading/writing shared reactive state through the object

# Constraints
- The shared fields that should drive UI updates **must be reactive** (e.g., `reactiveVal()` or `reactiveValues()`).
- Avoid using global variables; instantiate the R6 object inside `server()`.

# Algorithm / approach
1. **Define an R6 class** whose fields represent shared app state.
2. Make shared fields **reactive** (commonly `reactiveVal()` per field).
3. Provide **methods** on the class to update state (`set_*()`, `reset()`, `bump()`, etc.).
4. Instantiate the object once in the top-level `server()`.
5. Pass the object as an argument to every module server function that needs it.
6. In outputs/reactives, call `state$field()` to read (and therefore register dependencies).

# Example (minimal)
See `examples/app.R` for a runnable app.

Key idea:

```r
state <- AppState$new()
mod_writer_server("writer", state = state)
mod_reader_server("reader", state = state)
```

Where `AppState` wraps `reactiveVal()` fields:

```r
AppState <- R6::R6Class(
  "AppState",
  public = list(
    text = NULL,
    initialize = function(){
      self$text <- shiny::reactiveVal("")
    },
    set_text = function(x){
      self$text(as.character(x))
    }
  )
)
```

# Failure modes / debugging
- **No UI updates**: you stored plain values in the R6 (e.g., `self$x <- 1`) instead of reactive fields.
- **Hard-to-track reactivity**: too many automatic invalidations; consider triggering updates explicitly (e.g., event-based observers) and keeping observers small.
- **App-level coupling grows**: if the R6 becomes a “god object”, split it into domain stores (e.g., `UserState`, `DataState`).

# References
- See `SOURCES.md` for links and the practical `minifying` example where an R6 object is passed to modules.
