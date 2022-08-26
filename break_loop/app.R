library(shiny)

ui <- fluidPage(
  actionButton("start", "Start"),
  actionButton("stop", "Stop")
)

server <- function(input, output) {

  observe({
    while (TRUE) { ## CAN I CHANGE THIS TRUE? RV? TXT ON DISK?!...
      message("Cycling")

      if (TRUE) { ## ... OR BETTER SOME INTERNAL BREAKING CHECK?!
        message("Hard-coded break from the 'start' observer loop")
        break
      }
    }
  }) |>
    bindEvent(input$start)

  observe({
    ## WHAT CAN I PUT HERE?!
    message("I am triggered, can I stop the 'start' observer loop?!")
  }) |>
    bindEvent(input$stop)
}

# Run the application
shinyApp(ui = ui, server = server)
