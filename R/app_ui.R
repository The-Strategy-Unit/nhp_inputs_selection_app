use_leafletjs <- function() {
  htmltools::htmlDependency(
    name = "leaflet",
    version = "1.9.4",
    src = c(href = "https://unpkg.com/leaflet@1.9.4/dist"),
    script = "leaflet.js",
    stylesheet = "leaflet.css"
  )
}

map_dependency <- function(carto_api_key = NULL) {
  htmltools::htmlDependency(
    name = "map",
    version = "1.0.0",
    src = c(file = app_sys("www")),
    script = "map.js",
    head = if (!is.null(carto_api_key)) {
      htmltools::HTML(glue::glue(
        '<script>window.CARTO_API_KEY = "{carto_api_key}";</script>'
      ))
    }
  )
}

app_ui <- function(request) {
  shiny::addResourcePath(
    "www",
    app_sys("www")
  )

  carto_api_key <- Sys.getenv("CARTO_API_KEY")

  shiny::tagList(
    shiny::tags$head(
      shinyjs::useShinyjs(),
      use_leafletjs(),
      map_dependency(carto_api_key)
    ),
    ui_body()
  )
}


ui_body <- function() {
  # each of the columns is created in it's own variable

  # left column contains the documentation for this module
  left_column <- bslib::card(
    fill = FALSE,
    shiny::HTML(
      markdown::mark_html(
        app_sys("home.md"),
        output = FALSE,
        template = FALSE
      )
    )
  )

  # middle column contains the inputs that the user is going to set
  middle_column <- shiny::tagList(
    bslib::card(
      fill = FALSE,
      bslib::card_header(
        "Select Provider and Baseline",
        class = "bg-primary"
      ),
      bslib::card_body(
        shiny::selectInput(
          "dataset",
          "Provider",
          choices = NULL,
          selectize = TRUE,
          width = "100%"
        ),
        shiny::selectInput(
          "start_year",
          "Baseline Financial Year",
          # TODO: revisit why start year and end year are formatted differently
          choices = c("2023/24" = 202324, "2024/25" = 202425),
          selected = as.character(
            (years[["baseline_default"]] * 100) +
              ((years[["baseline_default"]] + 1) %% 100)
          ),
          width = "100%"
        ),
        shiny::div(
          id = "default_start_warning",
          style = "margin-bottom: 1rem;",
          shiny::icon("circle-info"),
          "Note that 2024/25 is the default year."
        ),
        shiny::div(
          id = "baseline_warning",
          style = "margin-bottom: 1rem;",
          shiny::icon("triangle-exclamation"),
          "You must",
          shiny::a(
            "request your detailed baseline data",
            href = paste0(
              "mailto:mlcsu.su.datascience@nhs.net?subject=NHP request: ",
              "detailed baseline data&body=I am requesting the detailed ",
              "baseline data for [scheme name] for financial year [YYYY/YY], as ",
              "instructed in the NHP inputs app."
            )
          ),
          "and review it before you run the model."
        ),
        shiny::selectInput(
          "end_year",
          "Model Financial Year",
          choices = generate_year_dropdown_choices(
            (years[["baseline_default"]] + 1):years[["horizon_max"]]
          ),
          selected = as.character(years[["horizon_default"]]),
          width = "100%"
        )
      )
    ),
    bslib::card(
      fill = FALSE,
      bslib::card_header("Scenario", class = "bg-primary"),
      bslib::card_body(
        shinyjs::disabled(
          shiny::radioButtons(
            "scenario_type",
            NULL,
            c(
              "Create new from scratch",
              "Create new from existing",
              "Edit existing"
            ),
            inline = TRUE
          )
        ),
        shinyjs::hidden(
          shiny::div(
            id = "upgrade_warning",
            style = "margin-bottom: 1rem;",
            shiny::icon("circle-info"),
            "Editing an existing scenario will automatically upgrade it to",
            "the latest model version. See",
            shiny::a(
              "the model updates page",
              href = paste0(
                "https://connect.strategyunitwm.nhs.uk/nhp/project_information/",
                "project_plan_and_summary/model_updates.html"
              )
            ),
            "for a full list of changes."
          )
        ),
        shinyjs::hidden(
          shiny::selectInput(
            "previous_scenario",
            "Previous Scenario",
            NULL,
            width = "100%"
          )
        ),
        shinyjs::hidden(
          shiny::div(
            id = "pop_proj_warning",
            style = "margin-bottom: 1rem;",
            shiny::icon("circle-info"),
            "Your scenario will be upgraded to work with the latest version of",
            "the model. From v4.0 the model uses the 2022 ONS population",
            "projections, so your population-growth selections will be reset to",
            "the new default. Please review this change."
          )
        ),
        shinyjs::hidden(
          shiny::div(
            id = "start_year_warning",
            style = "margin-bottom: 1rem;",
            shiny::icon("triangle-exclamation"),
            "The selected scenario has a baseline year prior to 2023/24 and",
            "cannot be upgraded. See",
            shiny::a(
              "the model updates page",
              href = paste0(
                "https://connect.strategyunitwm.nhs.uk/nhp/project_information/",
                "project_plan_and_summary/model_updates.html#v4.0.0"
              )
            ),
            "for reasoning"
          )
        ),
        shinyjs::hidden(
          shiny::div(
            id = "ndg_warning",
            style = "margin-bottom: 1rem;",
            shiny::icon("triangle-exclamation"),
            "You cannot upgrade a scenario that contains Variant 1 of the",
            "non-demographic growth (NDG) adjustment. See",
            shiny::a(
              "the model updates page",
              href = paste0(
                "https://connect.strategyunitwm.nhs.uk/nhp/project_information/",
                "project_plan_and_summary/model_updates.html#v3.3"
              ),
              "for reasoning."
            )
          )
        ),
        shiny::textInput("scenario", "Name", width = "100%"),
        shiny::div(
          id = "naming_guidance",
          style = "margin-top: -5px; margin-bottom: 8px",
          "Please follow",
          shiny::a(
            "the model-run naming guidelines.",
            href = "https://connect.strategyunitwm.nhs.uk/nhp/project_information/user_guide/naming_scenarios.html"
          ),
        ),
        shiny::uiOutput("start_button")
      )
    ),
    shiny::div(
      class = "nhp-dropdown-overflow-card",
      bslib::card(
        fill = FALSE,
        bslib::card_header(
          shiny::tags$button(
            type = "button",
            class = "btn btn-link p-0 text-start w-100",
            `data-bs-toggle` = "collapse",
            `data-bs-target` = "#advanced-options-collapse",
            `aria-expanded` = "false",
            `aria-controls` = "advanced-options-collapse",
            "Advanced Options"
          ),
          class = "bg-primary"
        ),
        bslib::card_body(
          id = "advanced-options-collapse",
          class = "collapse",
          shiny::numericInput(
            "seed",
            "Seed",
            sample(1:100000, 1),
            width = "100%"
          ),
          shiny::selectInput(
            "model_runs",
            "Model Runs",
            choices = c(256, 512, 1024),
            selected = 256,
            width = "100%"
          ),
          shinyjs::disabled(
            shiny::selectizeInput(
              "app_version",
              "Model Version",
              choices = app_version_choices(),
              options = list(dropdownParent = "body"),
              width = "100%"
            )
          ),
          shinyjs::disabled(
            shinyjs::hidden(
              shiny::selectizeInput(
                "selected_user",
                "Selected User",
                choices = NULL,
                options = list(dropdownParent = "body"),
                width = "100%"
              )
            )
          )
        )
      )
    )
  )

  # right column contains the outputs in the home module (map and peers list)
  right_column <- shiny::tagList(
    bslib::card(
      fill = FALSE,
      bslib::card_header(
        "Map of Selected Provider and Peers",
        class = "bg-primary"
      ),
      bslib::card_body(
        shiny::tags$div(
          id = "provider_peers_map",
          style = "height:730px;"
        )
      )
    ),
    bslib::card(
      fill = FALSE,
      bslib::card_header(
        shiny::tags$button(
          type = "button",
          class = "btn btn-link p-0 text-start w-100",
          `data-bs-toggle` = "collapse",
          `data-bs-target` = "#peers-list-collapse",
          `aria-expanded` = "false",
          `aria-controls` = "peers-list-collapse",
          "Peers (from NHS Trust Peer Finder Tool)"
        ),
        class = "bg-primary"
      ),
      bslib::card_body(
        id = "peers-list-collapse",
        class = "collapse",
        shinycssloaders::withSpinner(
          shiny::htmlOutput("peers_list")
        )
      )
    )
  )

  navbar <- shiny::tags$nav(
    class = "navbar navbar-expand-lg bg-primary",
    htmltools::tags$div(
      class = "navbar-brand",
      htmltools::h1("NHP Model Inputs", id = "page-title")
    )
  )

  theme <- ui_theme()

  # build the home page outputs
  shiny::tags$div(
    navbar,

    bslib::page_fluid(
      title = "NHP: Inputs Selection",
      theme = theme,
      bslib::layout_columns(
        col_widths = c(4, 4, 4),
        left_column,
        middle_column,
        right_column
      )
    )
  )
}

ui_theme <- function() {
  brand <- brand.yml::read_brand_yml(app_sys("_brand.yml"))

  bslib::bs_theme(brand = brand) |>
    bslib::bs_add_rules(
      sass::sass_file(app_sys("www/styles.scss"))
    )
}
