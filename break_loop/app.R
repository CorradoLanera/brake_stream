# CREDITS: The following solution was inspired by the one discovered
#          at https://blog.fellstat.com/?p=407 (last access: 2022-08-27)

library(shiny)
library(promises)
library(future)
plan(multisession, workers = 2)




ui <- fluidPage(
  actionButton("start", "Start"),
  actionButton("stop", "Stop"),
  textOutput("status")
)

server <- function(input, output) {

# Setup -----------------------------------------------------------

  status_file <- fs::file_temp()
  onStop({
    function() {
      message("Final status: ", get_status())
      if (fs::file_exists(status_file)) unlink(status_file)
      plan(sequential)
    }
  })

  get_status <- function() {
    readLines(status_file)
  }

  set_status <- function(msg) {
    writeLines(msg, status_file)
  }

  fire_interrupt <- function() {
    set_status("Interrupt")
    message("Setting status: Interrupt")
  }

  fire_ready <- function() {
    set_status("Ready")
  }

  fire_strange <- function() {
    set_status("Strange things happened...")
  }


  fire_running <- function(perc = NULL) {
    if (is.null(perc)) return(set_status("Running..."))
    set_status(paste0("Running... (", perc, " % completed)"))
  }

  is_status <- function(status) {
    stringr::str_detect(
      stringr::str_to_lower(get_status()),
      stringr::str_to_lower(status)
    )
  }

  print_progress <- function(i) {
    if (i %% 50 == 0) {
      cat(i, "\n")
    } else if (i %% 10 == 0) {
      cat("X")
    } else cat(".")
  }

  fire_ready()


  current_status <- reactive({
    invalidateLater(1e3)
    get_status()
  })

  observe({
    message("Button start clicked")

    if (is_status("running")) {
      showNotification(
        "Already running.
         You cannot start new run if the current is ongoing.
         Please, wait or interrupt the current run (stop button).
        ",
        type = "warning"
      )
      message("Cycle doesn't started (again)")
      return(NULL)
    }
    if (!is_status("ready")) {
      showNotification(
        "Not ready.
         Have you done all settings?
        ",
        type = "warning"
      )
      message("Cycle doesn't started (not ready)")
      return(NULL)
    }

    fire_running()
    showNotification("Cycle started!")
    message("Cycle started.")

    res <- future({
      i <- 1
      while (TRUE) {
        print_progress(i)
        Sys.sleep(0.2)

        if (is_status("interrupt")) break

        fire_running(round(1 - 1/i, 2 + log10(i)) * 100)
        i <- i + 1
      }
      message("Cycle interrupted!")
    })

    res <- catch(
      res,
      function(e) {
        message(e$message)
        fire_strange()
        showNotification(e$message, type = "warning")
      }
    )

    res <- finally(
      res,
      function() if (!is_status("strange")) fire_ready()
    )

    # Return something other than the promise so shiny remains responsive
    NULL
  }) |>
    bindEvent(input$start)

  observe({
    message("Button stop clicked")

    if (is_status("ready")) {
      showNotification(
        "Cycle is not running.
         You cannot interrupt a not running cycle...
         You can start a cycle to interrupt (start button).
        ",
        type = "warning"
      )
      message("Ready cycle, it doesn't interrupted")
      return(NULL)
    }

    if (is_status("interrupt")) {
      showNotification(
        "Already interrupted.
         You cannot interrupt a not running cycle...
         If ready, you can start a cycle to interrupt (start button).
        ",
        type = "warning"
      )
      message("Cycle doesn't interrupted (again)")
      return(NULL)
    }

    fire_interrupt()
    showNotification("Cycle stopped")
  }) |>
    bindEvent(input$stop)


  output$status <- renderText({
    paste0("Current status: ", current_status())
  })
}

# Run the application
shinyApp(ui = ui, server = server)
