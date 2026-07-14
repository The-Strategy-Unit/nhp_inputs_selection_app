## YEARS ----

years <- list(
  horizon_max = Sys.getenv("YEAR_HORIZON_MAX", "2047"),
  horizon_default = Sys.getenv("YEAR_HORIZON_DEFAULT", "2041"),
  baseline_default = Sys.getenv("YEAR_BASELINE_DEFAULT", "2024"),
  baseline_min = Sys.getenv("YEAR_BASELINE_MIN", "2023")
) |>
  purrr::map(as.numeric)

format_year_as_fyear <- function(year) {
  stopifnot(
    "invalid value for year" = all(year >= 1000 & year <= 9999)
  )

  paste(year, (year + 1) %% 100, sep = "/")
}

generate_year_dropdown_choices <- function(years) {
  fyears <- format_year_as_fyear(years)
  purrr::set_names(as.character(years), fyears)
}
