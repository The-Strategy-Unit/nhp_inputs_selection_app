#' @importFrom rlang .data .env `!!!`
NULL

app_version_choices <- function() {
  jsonlite::fromJSON(
    Sys.getenv(
      "APP_VERSION_CHOICES",
      "[\"dev\"]"
    )
  )
}

load_params <- function(file) {
  p <- jsonlite::read_json(file, simplifyVector = TRUE)

  # To trigger UI warnings
  prior_app_version <- p$app_version
  if (is.null(prior_app_version)) {
    prior_app_version <- "new"
  }
  attr(p, "prior_app_version") <- prior_app_version

  # To trigger upgrade methods
  class(p) <- p$app_version
  unclass(upgrade_params(p))
}

params_path <- function(user, dataset) {
  path <- file.path(
    get_config("params_data_path"),
    "params",
    user %||% "[development]",
    dataset
  )

  dir.create(path, FALSE, TRUE)

  path
}

params_filename <- function(user, dataset, scenario) {
  file.path(
    params_path(user, dataset),
    paste0(scenario, ".json")
  )
}

# check to see whether the app is running locally or in production
is_local <- function() {
  Sys.getenv("POSIT_PRODUCT") != "CONNECT"
}

format_nhs_trust_name <- function(name) {
  name |>
    stringr::str_to_title() |>
    stringr::str_replace_all("Nhs", "NHS") |>
    stringr::str_replace_all("And", "and")
}


peers_table <- function(selected_peers) {
  selected_peers |>
    dplyr::filter(.data[["is_peer"]]) |>
    dplyr::select("ODS Code" = "org_id", "Trust" = "name") |>
    gt::gt()
}

app_sys <- function(...) {
  system.file(..., package = "nhp.inputs.selection.app")
}

get_config <- function(
  value,
  config = Sys.getenv("R_CONFIG_ACTIVE", "default")
) {
  config::get(value, file = app_sys("config.yml"), config = config)
}
