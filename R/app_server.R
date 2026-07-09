app_server <- function(input, output, session) {
  # static data ----
  peers <- readRDS(app_sys("peers.Rds"))

  providers <- yyjsonr::read_geojson_file(app_sys(
    "www/provider_locations.geojson"
  )) |>
    as.data.frame() |>
    dplyr::mutate(
      dplyr::across("name", format_nhs_trust_name)
    ) |>
    dplyr::transmute(
      name = paste0(.data[["name"]], " (", .data[["org_id"]], ")"),
      org_id = .data[["org_id"]]
    ) |>
    dplyr::arrange(.data[["name"]])

  # reactives ----

  current_user <- shiny::reactive({
    session$user %||% "[development]"
  })

  # each time the user connects we create a temporary file which is what is passed to the main inputs app

  tempfile_name <- shiny::reactive({
    path <- file.path(
      get_config("params_data_path"),
      "tmp"
    )
    dir.create(path, FALSE, TRUE)
    tempfile("", tmpdir = path)
  })

  # only show the providers that a user is allowed to access
  selected_providers <- shiny::reactive({
    g <- session$groups
    providers <- tibble::deframe(providers)

    if ((is.null(g) || any(c("nhp_devs", "nhp_power_users") %in% g))) {
      return(providers)
    }

    a <- g |>
      stringr::str_subset("^nhp_provider_") |>
      stringr::str_remove("^nhp_provider_")

    p <- intersect(providers, a)
    providers[providers %in% p]
  })

  # when the user changes the provider (dataset), get the list of peers for that provider
  selected_peers <- shiny::reactive({
    p <- shiny::req(input$dataset)

    providers |>
      dplyr::semi_join(
        peers |>
          dplyr::filter(.data$procode == p),
        by = c("org_id" = "peer")
      ) |>
      dplyr::mutate(is_peer = .data$org_id != p)
  }) |>
    shiny::bindEvent(input$dataset)

  shiny::observe({
    peers <- shiny::req(selected_peers()) |>
      _[["org_id"]] |>
      unique()

    session$sendCustomMessage("selectedPeersUpdate", peers)
  }) |>
    shiny::bindEvent(selected_peers())

  # the scenario must have some validation applied to it - the next few chunks handle this
  scenario_validation <- shiny::reactive({
    s <- input$scenario
    f <- params_filename(current_user(), input$dataset, input$scenario)

    shiny::validate(
      shiny::need(
        s != "",
        "Scenario name must be completed in order to proceed",
        "Scenario"
      ),
      shiny::need(
        !stringr::str_detect(s, "[^a-zA-Z0-9\\-]"),
        "Scenario can only contain letters, numbers, and - characters",
        "Scenario"
      ),
      shiny::need(
        input$scenario_type == "Edit existing" || !file.exists(f),
        "Scenario already exists",
        "Scenario"
      )
    )

    # scenario is valid, so return TRUE. the validate function will return an error if there are issues
    TRUE
  }) |>
    shiny::bindEvent(input$dataset, input$scenario, input$scenario_type)

  # load the selected params
  # if the user chooses to create new from scratch, we use the default parameters file
  # otherwise, load the values for the scenario the user selected
  params <- shiny::reactive({
    default_params <- app_sys("default_params.json")
    file <- if (input$scenario_type == "Create new from scratch") {
      default_params
    } else {
      params_filename(
        input$selected_user,
        input$dataset,
        input$previous_scenario
      )
    }

    # make sure the file exists before loading it
    shiny::req(file.exists(file))
    p <- load_params(file)

    # if we use the default parameters
    if (file == default_params) {
      p$seed <- sample(1:100000, 1)
    }
    p$user <- current_user()

    return(p)
  }) |>
    shiny::bindEvent(
      input$dataset,
      input$scenario_type,
      input$previous_scenario
    )

  params_with_inputs <- shiny::reactive({
    p <- params()
    p$dataset <- input$dataset
    p$scenario <- input$scenario
    p$seed <- input$seed
    p$model_runs <- as.numeric(input$model_runs)
    p$start_year <- input$start_year
    p$end_year <- as.numeric(input$end_year)
    p$app_version <- input$app_version

    p
  })

  filename <- shiny::reactive({
    shiny::req(scenario_validation())
    params_filename(input$selected_user, input$dataset, input$scenario)
  })

  # observers ----

  shiny::observe({
    users <- c(
      dir(
        file.path(
          get_config("params_data_path"),
          "params"
        )
      ),
      current_user()
    ) |>
      unique() |>
      sort()

    shiny::updateSelectInput(
      session,
      "selected_user",
      choices = users,
      selected = current_user()
    )
  })

  shiny::observe({
    is_power_user <- any(c("nhp_devs", "nhp_power_users") %in% session$groups)
    if (is_local() || is_power_user) {
      shinyjs::enable("app_version")
      shinyjs::enable("selected_user")
      shinyjs::show("selected_user")
    }
  })

  # when params change, update inputs
  shiny::observe({
    p <- shiny::req(params())

    valid_start_year <- (p$start_year >= 1000) && (p$start_year <= 9999)
    stopifnot(
      "start_year is coming through as an fyear, should be yyyy" = valid_start_year
    )

    if (p$start_year >= years[["baseline_min"]]) {
      y <- p$start_year * 100 + p$start_year %% 100 + 1
      # we don't need to update dataset: the parameters files that are listed in
      # the previous scenario dropdown are already tied to that provider
      shiny::updateSelectInput(session, "start_year", selected = y)
    }

    selected_end_year <- p$end_year
    if (
      selected_end_year <= p$start_year ||
        selected_end_year > years[["horizon_max"]]
    ) {
      selected_end_year <- years[["horizon_max"]]
    }

    shiny::updateSelectInput(
      session,
      "end_year",
      selected = as.character(p$end_year)
    )
    shiny::updateNumericInput(session, "seed", value = p$seed)
    shiny::updateSelectInput(session, "model_runs", selected = p$model_runs)
    shiny::updateSelectInput(session, "app_version", selected = p$app_version)
  }) |>
    shiny::bindEvent(params())

  # update the dataset dropdown when the list of providers changes
  shiny::observe({
    shiny::updateSelectInput(
      session,
      "dataset",
      choices = selected_providers()
    )
  }) |>
    shiny::bindEvent(selected_providers())

  # the end-year range should be 1 year after the start year to max horizon
  shiny::observe({
    start_yr <- as.numeric(stringr::str_sub(input$start_year, 1, 4))

    fy_choices <- generate_year_dropdown_choices(
      (start_yr + 1):years[["horizon_max"]]
    )

    # Set end year to default horizon otherwise the year stored in existing params
    selected_end_year <- if (input$scenario_type == "Create new from scratch") {
      years[["horizon_default"]]
    } else {
      shiny::req(params())$end_year
    }

    shiny::updateSelectInput(
      session,
      "end_year",
      choices = fy_choices,
      selected = selected_end_year
    )
  }) |>
    shiny::bindEvent(input$start_year)

  # when a user changes the dataset, reset the scenario box back to default (create new from scratch)
  shiny::observe({
    ds <- shiny::req(input$dataset)

    saved_params <- params_path(input$selected_user, ds) |>
      dir(pattern = "*.json") |>
      stringr::str_remove("\\.json$")

    shiny::updateRadioButtons(
      session,
      "scenario_type",
      selected = "Create new from scratch"
    )
    shiny::updateTextInput(
      session,
      "scenario",
      value = ""
    )
    shinyjs::toggleState("scenario_type", condition = length(saved_params) > 0)

    shiny::updateSelectInput(
      session,
      "previous_scenario",
      choices = saved_params
    )
  }) |>
    shiny::bindEvent(input$dataset, input$selected_user)

  # watch the scenario inputs
  # this shows/hides some of the inputs in the scenario box, depending on what is selected in the scenario_type radio
  # buttons
  shiny::observe({
    if (input$selected_user != current_user()) {
      shinyjs::disable("scenario_type")

      shiny::updateCheckboxInput(
        session,
        "scenario_type",
        value = "Create new from existing"
      )
    }

    if (input$scenario_type == "Create new from scratch") {
      shinyjs::show("scenario")
      shinyjs::enable("scenario")
      shinyjs::hide("upgrade_warning")
      shinyjs::hide("pop_proj_warning")
      shinyjs::hide("previous_scenario")
      shinyjs::hide("start_year_warning")
      shinyjs::hide("ndg_warning")
      shinyjs::show("naming_guidance")
      shiny::updateTextInput(session, "scenario", value = "")
    } else if (input$scenario_type == "Create new from existing") {
      shinyjs::show("scenario")
      shinyjs::show("previous_scenario")
      shinyjs::show("naming_guidance")
      shinyjs::hide("upgrade_warning")
      shiny::updateTextInput(session, "scenario", value = "")
    } else if (input$scenario_type == "Edit existing") {
      shinyjs::hide("scenario")
      shinyjs::show("previous_scenario")
      shinyjs::hide("naming_guidance")
      shinyjs::show("upgrade_warning")
      shiny::updateTextInput(
        session,
        "scenario",
        value = input$previous_scenario
      )
    }
  }) |>
    shiny::bindEvent(
      input$scenario_type,
      input$previous_scenario
    )

  shiny::observe({
    # Toggle element visibility if selecting existing scenarios
    if (stringr::str_detect(input$scenario_type, "existing")) {
      p <- shiny::req(params())

      # Warn about forced upgrade to 2022 pop projections if prior scenario was
      # <v4.0 (ignore warning if dev or new scenario).

      version_string <- get_version_from_attr(p)
      is_dev_or_new <- stringr::str_detect(version_string, "^(dev|new)$")

      shinyjs::toggle(
        "pop_proj_warning",
        condition = !is_dev_or_new && extract_major_version(version_string) < 4
      )

      # Warn user they can't upgrade certain scenarios, disable interaction

      is_deprecated_start_year <- p[["start_year"]] < years[["baseline_min"]]
      is_ndg1 <- p[["non-demographic_adjustment"]][["variant"]] == "variant_1"

      if (is_deprecated_start_year) {
        shinyjs::show("start_year_warning")
        shinyjs::hide("scenario")
        shinyjs::hide("start_button")
        shinyjs::hide("naming_guidance")
        shinyjs::hide("pop_proj_warning")
      } else if (is_ndg1) {
        shinyjs::show("ndg_warning")
        shinyjs::hide("scenario")
        shinyjs::hide("start_button")
        shinyjs::hide("naming_guidance")
        shinyjs::hide("pop_proj_warning")
      } else {
        shinyjs::hide("start_year_warning")
        shinyjs::hide("ndg_warning")
        shinyjs::enable("scenario")
        shinyjs::show("start_button")
      }
    }

    # Reset element visibility if starting from scratch
    if (input$scenario_type == "Create new from scratch") {
      shinyjs::hide("pop_proj_warning")
      shinyjs::hide("start_year_warning")
      shinyjs::hide("ndg_warning")
      shinyjs::enable("scenario")
      shinyjs::show("start_button")
    }
  }) |>
    shiny::bindEvent(
      input$scenario_type,
      input$previous_scenario
    )

  # 'create new' radio button should force model version dropdown to latest
  shiny::observe({
    if (input$scenario_type == "Create new from scratch") {
      shiny::updateSelectInput(
        session,
        "app_version",
        selected = app_version_choices()[1]
      )
    }
  }) |>
    shiny::bindEvent(input$scenario_type)

  # renders ----
  output$peers_list <- shiny::renderUI({
    selected_peers() |>
      peers_table() |>
      gt::as_raw_html() |>
      shiny::HTML()
  })

  output$start_button <- shiny::renderUI({
    if (scenario_validation()) {
      f <- tempfile_name()
      p <- shiny::req(params_with_inputs())
      jsonlite::write_json(p, f, pretty = TRUE, auto_unbox = TRUE)

      # used by the variable in get_config("app_url")
      version <- stringr::str_replace(p$app_version, "\\.", "-") # nolint

      url <- glue::glue(
        get_config("app_url"),
        "?",
        utils::URLencode(basename(f))
      )

      shiny::tags$a(
        "Start",
        class = "btn btn-success",
        href = url
      )
    }
  }) |>
    shiny::bindEvent(filename(), params_with_inputs())

  # return ----
  NULL
}
