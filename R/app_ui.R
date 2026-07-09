app_ui <- function(request) {
  shiny::addResourcePath(
    "www",
    app_sys("www")
  )

  shiny::tagList(
    shiny::tags$head(
      shiny::tags$title("NHP: Inputs Selection"),
      shinyjs::useShinyjs(),
      shiny::tags$link(
        rel = "stylesheet",
        href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      ),
      shiny::tags$script(
        src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
      ),
      shiny::tags$script(src = "www/map.js")
    ),
    bs4Dash::bs4DashPage(
      bs4Dash::dashboardHeader(disable = TRUE),
      bs4Dash::dashboardSidebar(disable = TRUE),
      ui_body(),
      help = NULL,
      dark = NULL
    )
  )
}


ui_body <- function() {
  # each of the columns is created in it's own variable

  # left column contains the documentation for this module
  left_column <- shiny::column(
    width = 4,
    bs4Dash::box(
      collapsible = FALSE,
      headerBorder = FALSE,
      width = 12,
      shiny::HTML(markdown::mark_html(
        app_sys("home.md"),
        output = FALSE,
        template = FALSE
      ))
    )
  )

  # middle column contains the inputs that the user is going to set
  middle_column <- shiny::column(
    width = 4,
    bs4Dash::box(
      title = "Select Provider and Baseline",
      collapsible = FALSE,
      width = 12,
      shiny::selectInput(
        "dataset",
        "Provider",
        choices = NULL,
        selectize = TRUE
      ),
      shiny::selectInput(
        "start_year",
        "Baseline Financial Year",
        # TODO: revisit why start year and end year are formatted differently
        choices = c("2023/24" = 202324, "2024/25" = 202425),
        selected = as.character(
          (years[["baseline_default"]] * 100) +
            ((years[["baseline_default"]] + 1) %% 100)
        )
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
          ),
        ),
        "and review it before you run the model."
      ),
      shiny::selectInput(
        "end_year",
        "Model Financial Year",
        choices = generate_year_dropdown_choices(
          (years[["baseline_default"]] + 1):years[["horizon_max"]]
        ),
        selected = as.character(years[["horizon_default"]])
      )
    ),
    bs4Dash::box(
      title = "Scenario",
      collapsible = FALSE,
      width = 12,
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
          NULL
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
      shiny::textInput("scenario", "Name"),
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
    ),
    bs4Dash::box(
      title = "Advanced Options",
      width = 12,
      collapsed = TRUE,
      shiny::numericInput("seed", "Seed", sample(1:100000, 1)),
      shiny::selectInput(
        "model_runs",
        "Model Runs",
        choices = c(256, 512, 1024),
        selected = 256
      ),
      shinyjs::disabled(
        shiny::selectInput(
          "app_version",
          "Model Version",
          choices = app_version_choices()
        )
      ),
      shinyjs::disabled(
        shinyjs::hidden(
          shiny::selectInput("selected_user", "Selected User", choices = NULL)
        )
      )
    )
  )

  # right column contains the outputs in the home module (map and peers list)
  right_column <- shiny::column(
    width = 4,
    bs4Dash::box(
      title = "Map of Selected Provider and Peers",
      width = 12,
      shiny::tags$div(
        id = "provider_peers_map",
        style = "height:730px;"
      )
    ),
    bs4Dash::box(
      title = "Peers (from NHS Trust Peer Finder Tool)",
      width = 12,
      collapsed = TRUE,
      shinycssloaders::withSpinner(
        shiny::htmlOutput("peers_list")
      )
    )
  )

  # build the home page outputs
  bs4Dash::bs4DashBody(
    htmltools::h1("NHP Model Inputs"),
    shiny::fluidRow(
      left_column,
      middle_column,
      right_column
    )
  )
}
