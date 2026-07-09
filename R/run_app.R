#' Run the Inputs Selection App
#'
#' Runs the inputs selection app in a shiny session. This function is called by
#' the `run_app()` function in the `app.R` file.
#'
#' @param ... A list of options to pass to the shiny app. See `?shiny::shinyApp()` for details.
#'
#' @export
run_app <- function(...) {
  shiny::shinyApp(app_ui, app_server, options = list(...))
}
