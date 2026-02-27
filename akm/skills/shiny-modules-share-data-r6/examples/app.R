# Minimal runnable example: share data across Shiny modules with an R6 store
#
# Run:
#   Rscript skills/shiny-modules-share-data/examples/app.R
#
# (This starts a Shiny app; stop with Esc/Ctrl+C.)

library(shiny)

AppState <- R6::R6Class(
  "AppState",
  public = list(
    text = NULL,
    counter = NULL,

    initialize = function() {
      self$text <- reactiveVal("")
      self$counter <- reactiveVal(0)
    },

    set_text = function(x) {
      self$text(as.character(x))
      invisible(NULL)
    },

    bump = function() {
      self$counter(self$counter() + 1)
      invisible(NULL)
    }
  )
)

mod_writer_ui <- function(id) {
  ns <- NS(id)
  tagList(
    textInput(ns("txt"), "Text to share"),
    actionButton(ns("send"), "Update shared text"),
    actionButton(ns("bump"), "Increment shared counter")
  )
}

mod_writer_server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$send, {
      state$set_text(input$txt)
    })

    observeEvent(input$bump, {
      state$bump()
    })
  })
}

mod_reader_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h4("Shared state"),
    verbatimTextOutput(ns("shared"))
  )
}

mod_reader_server <- function(id, state) {
  moduleServer(id, function(input, output, session) {
    output$shared <- renderPrint({
      # These reactiveVal() calls are the reactive dependency.
      list(
        text = state$text(),
        counter = state$counter()
      )
    })
  })
}

ui <- fluidPage(
  titlePanel("R6 store shared across modules"),
  fluidRow(
    column(6, mod_writer_ui("writer")),
    column(6, mod_reader_ui("reader"))
  )
)

server <- function(input, output, session) {
  state <- AppState$new()
  mod_writer_server("writer", state = state)
  mod_reader_server("reader", state = state)
}

shinyApp(ui, server)
