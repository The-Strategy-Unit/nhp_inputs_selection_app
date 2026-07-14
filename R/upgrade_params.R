#' Upgrade model parameters to the latest version
#'
#' Older model parameters are automatically upgraded to the latest version when loaded. This function is called by
#' `load_params()` in `ZZZ.R` and should not be called directly.
#'
#' @param p A list of model parameters to upgrade.
#' @export
upgrade_params <- function(p) {
  UseMethod("upgrade_params", p)
}

#' @exportS3Method
upgrade_params.default <- function(p) {
  p
}

# Insert above a new upgrade step for each new major or minor version

#' @exportS3Method
upgrade_params.v1.2 <- function(p) {
  p$health_status_adjustment <- TRUE
  class(p) <- p$app_version <- "v2.0"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v2.0 <- function(p) {
  class(p) <- p$app_version <- "v2.1"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v2.1 <- function(p) {
  class(p) <- p$app_version <- "v2.2"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v2.2 <- function(p) {
  class(p) <- p$app_version <- "v3.0"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.0 <- function(p) {
  class(p) <- p$app_version <- "v3.1"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.1 <- function(p) {
  class(p) <- p$app_version <- "v3.2"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.2 <- function(p) {
  # Change NDG params structure

  ndg_values <- p[["non-demographic_adjustment"]]

  # Build new key-value format, assume NDG variant 2
  p[["non-demographic_adjustment"]] <- list(
    "variant" = "variant_2",
    "value-type" = "year-on-year-growth",
    "values" = ndg_values
  )

  # Overwrite variant if variant 1
  is_ndg1 <- identical(ndg_values[["ip"]][["non-elective"]], c(1.0194, 1.0240))
  if (is_ndg1) {
    p[["non-demographic_adjustment"]][["variant"]] <- "variant_1"
  }

  class(p) <- p$app_version <- "v3.3"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.3 <- function(p) {
  # Remove deprecated AEC mitigators

  aec_mitigators <- paste0(
    "ambulatory_emergency_care_",
    c("low", "moderate", "high", "very_high")
  )

  for (mitigator in aec_mitigators) {
    p[["efficiencies"]][["ip"]][[mitigator]] <- NULL
    p[["time_profile_mappings"]][["efficiencies"]][["ip"]][[mitigator]] <- NULL
    p[["reasons"]][["efficiencies"]][["ip"]][[mitigator]] <- NULL
  }

  # remove the unused demographics file key
  if ("file" %in% names(p[["demographic_factors"]])) {
    p[["demographic_factors"]][["file"]] <- NULL
  }

  class(p) <- p$app_version <- "v3.4"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.4 <- function(p) {
  # Add (or overwrite) inequalities

  p <- utils::modifyList(
    p,
    list(inequalities = NULL), # model expects "inequalities": {}
    keep.null = TRUE # NULL list elements are usually discarded
  )

  class(p) <- p$app_version <- "v3.5"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.5 <- function(p) {
  # Set waiting list adjustment to 'off'

  p[["waiting_list_adjustment"]] <- list(ip = NULL, op = NULL)

  class(p) <- p$app_version <- "v3.6"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v3.6 <- function(p) {
  # Overwrite population growth selections with 'migration category' default
  # variant due to the addition of the new ONS 2022 projections.

  p[["demographic_factors"]][["variant_probabilities"]] <-
    list("migration_category" = 1)

  class(p) <- p$app_version <- "v4.0"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v4.0 <- function(p) {
  # Remove covid adjustment

  p[["covid_adjustment"]] <- NULL
  p[["time_profile_mappings"]][["covid_adjustment"]] <- NULL

  class(p) <- p$app_version <- "v4.1"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v4.1 <- function(p) {
  class(p) <- p$app_version <- "v4.2"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v4.2 <- function(p) {
  class(p) <- p$app_version <- "v4.3"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v4.3 <- function(p) {
  class(p) <- p$app_version <- "v4.4"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v4.4 <- function(p) {
  class(p) <- p$app_version <- "v5.0"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v5.0 <- function(p) {
  class(p) <- p$app_version <- "v5.1"
  upgrade_params(p)
}

#' @exportS3Method
upgrade_params.v5.1 <- function(p) {
  # Remove time-profile mappings

  p[["time_profile_mappings"]] <- NULL

  class(p) <- p$app_version <- "v5.2"
  upgrade_params(p)
}
