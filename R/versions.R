## VERSIONS ----

get_version_from_attr <- function(p) {
  prior_app_version <- attr(p, "prior_app_version")

  if (is.null(prior_app_version)) {
    stop("prior_app_version attribute not found on params object p.")
  }

  is_version <- stringr::str_detect(prior_app_version, "^v\\d{1,}\\.\\d{1,}$")
  is_dev_or_new <- stringr::str_detect(prior_app_version, "^(dev|new)$")
  if (!(is_version || is_dev_or_new)) {
    stop("prior_app_version attribute must be in the form 'v1.2' or 'dev'.")
  }

  prior_app_version
}

extract_major_version <- function(version_string) {
  is_dev_or_new <- stringr::str_detect(version_string, "^(dev|new)$")

  if (!is_dev_or_new) {
    version_string <- version_string |>
      stringr::str_remove("v") |>
      as.numeric() |>
      floor()
  }

  version_string
}
