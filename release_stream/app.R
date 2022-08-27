library(shiny)

ui <- fluidPage(
  actionButton("preview", "Take snapshot"),
  actionButton("start", "Start recording"),
  actionButton("stop", "Stop recording"),
  numericInput("index", "Camera index: ", min = 0, value = 0, step = 1),
  plotOutput("snapshot")
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  # Preview ---------------------------------------------------------

  test_out <- reactive({
    validate(need(input$index, "index must be provided"))
    my_stream <- Rvision::stream(input$index)
    withr::defer(Rvision::release(my_stream))
    Rvision::readNext(my_stream)
  }) |>
    bindEvent(input$preview)


  # Recording -------------------------------------------------------
  observe({
    req(input$index)
    my_stream <<- Rvision::stream(input$index)
    message("Streaming is ON")
  }) |>
    bindEvent(input$start)

  observe({
    ## rm(..., envir = parent.frame(1)) is hard-coded in
    ## Rvision:::release.Rcpp_Stream(); so it warns and doesn't remove
    ## my_stream, but it success in releasing it.
    suppressWarnings({ Rvision::release(my_stream) })
    rm(my_stream, envir = .GlobalEnv)
    message("Streaming is OFF")
  }) |>
    bindEvent(input$stop)


  # outputs ---------------------------------------------------------
  output$snapshot <- renderPlot({ plot(test_out()) })
}

# Run the application
shinyApp(ui = ui, server = server)
