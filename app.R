library(shiny)

ui <- fluidPage(
  titlePanel("Stop my stream, please!"),

  sidebarLayout(
    sidebarPanel(
      fluidRow(
        column(
          width = 12,
          h2("Buttons"),
          actionButton("preview", "Take snapshot")
        ),
        column(
          width = 12,
          actionButton("start", "Start recording"),
          actionButton("stop", "Stop recording")
        ),

        column(
          width = 12,
          h2("Set the settings"),
          numericInput(
            "index", "Camera index: ", min = 0, value = 0, step = 1
          ),
          h2("Check the settings"),
          textOutput("camera_idx"),
        )
      )
    ),
    mainPanel(
      h2("Your snapshot"),
      plotOutput("snapshot")
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  # Preview ---------------------------------------------------------

  # This works as a reactive because output$snapshot depends on it
  # when user invalidates preview, invalidates test_out, that
  # invalidates output$snapshot. As output it will be computed, so
  # it needs test_out, which will be called and updated.
  test_out <- reactive({
    withr::local_options(list(digits.secs = 6))
    validate(need(input$index, "index must be provided"))

    my_stream <- Rvision::stream(input$index)
    withr::defer(Rvision::release(my_stream))

    Rvision::readNext(my_stream)

  }) |>
    bindEvent(input$preview)


  # Recording -------------------------------------------------------

  observe({
    req(input$index)

    tmp_video_file <- tempfile("test-video", fileext = ".mp4")
    usethis::ui_info(
      "Video file at: {usethis::ui_value(tmp_video_file)}."
    )

    ## CANNOT PUT  `withr::defer(Rvision::release(my_stream))` HERE
    ## BECAUSE THIS IS CACHED, AND WHO KNOWS WHEN IT "EXITS"?!
    ##
    ## SO, I HAVE TO REACH THIS FROM OUTSIDE (THAT'S WHY `<<-`).
    ## BUT, I NEED A VALUE, AND I CANNOT USE REACTIVE (BECAUSE LAZYNESS)
    my_stream <<- Rvision::stream(input$index)

    my_buffer <<- Rvision::queue(
      x = my_stream, size = 30 * 10, overflow = "grow"
    )

    frame <- Rvision::readNext(my_buffer)
    my_writer <<- Rvision::videoWriter(
      outputFile = tmp_video_file,
      fourcc = "mpeg",
      fps = 30, height = nrow(frame), width = ncol(frame)
    )


    ## HERE I WOULD START THE (POSSIBLY INFINITE) RECORDING CYCLE
    usethis::ui_todo("Recording is ON")
    while (TRUE) { ## PUT HERE A REACTIVE?! READ A TEXTFILE ON DISK?!...
      Rvision::readNext(my_buffer, target = frame)

      Rvision::writeFrame(my_writer, frame)
      if (TRUE) { ## ... OR PUT HERE A SUITABLE CONDITION?!
        usethis::ui_info("Hardcoded exit from the 'start' observer.")
        break
      }
    }
  }) |>
    bindEvent(input$start)

  observe({
    if (exists("my_stream", envir = .GlobalEnv)) {
      suppressWarnings({
        ## rm(..., envir = parent.frame(1)) IS HARD-CODED, THAT WHY
        ## WE NEED TO SUPPRESS WARNINGS
        Rvision::release(my_writer)
        Rvision::release(my_buffer)
        Rvision::release(my_stream)
      })
      rm(my_stream, my_buffer, my_writer, envir = .GlobalEnv)
      usethis::ui_done("Recording is OFF")
    }
  }) |>
    bindEvent(input$stop)


  # outputs ---------------------------------------------------------

  output$camera_idx <- renderText({
    validate(need(input$index, "index must be provided"))
    paste0("Camera index is: ", input$index)
  })

  output$snapshot <- renderPlot({ plot(test_out()) })


}

# Run the application
shinyApp(ui = ui, server = server)
