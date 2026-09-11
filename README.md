<!-- badges: start -->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Check package](https://github.com/The-Strategy-Unit/nhp_inputs_selection_app/actions/workflows/check.yaml/badge.svg)](https://github.com/The-Strategy-Unit/nhp_inputs_selection_app/actions/workflows/check.yaml)
<!-- badges: end -->

## About

A web app to input the parameters needed to run scenarios through the New 
Hospital Programme (NHP) demand model.

The app is [deployed to Posit Connect](https://connect.strategyunitwm.nhs.uk/nhp/inputs/).
You must have an account and sufficient permissions to view it.

Results can then be viewed in [the outputs app](https://connect.strategyunitwm.nhs.uk/nhp/outputs/), 
which is generated from the [nhp_outputs](https://github.com/The-Strategy-Unit/nhp_outputs) repository.

You can find more information on 
[the NHP model project information site](https://connect.strategyunitwm.nhs.uk/nhp/project_information/), 
including [a diagram](https://connect.strategyunitwm.nhs.uk/nhp/project_information/project_plan_and_summary/components-overview.html) 
of how the components of the modelling process fit together.

In this app you can:

- select an existing scenario
- create a new scenario (from scratch or from an existing one)
- choose the NHP Inputs model version to open
- launch into the correct version of the Inputs app with the selected scenario parameters

This app is the entry point for managing scenario (JSON) files and provides the 
most recent NHP Inputs app version as a default selection.

## More detail on the app functionality

The selection app provides a guided workflow to:

1. Pick a provider (dataset) and baseline/model years.
2. Choose a scenario action:
   - Create new from scratch
   - Create new from existing
   - Edit existing
3. Set advanced options (seed, model runs, model version; user scope for power users).
4. Save parameters to a temporary JSON file.
5. Open the NHP Inputs app URL using that parameter file.

The app also:

- filters available providers by user groups
- shows a provider/peer map and peers list
- applies upgrade logic when older scenarios are loaded
- blocks upgrades for unsupported legacy scenarios (for example older baseline 
years or certain NDG - non demographic growth - variants)

## For developers

The guidance below is for the members of 
[the Strategy Unit's Data Science team](https://the-strategy-unit.github.io/data_science/), 
who built and maintain this app.

### Structure

Technically this app routes users to either the most recent version of inputs 
app or, if selected, a previous version of the inputs app.

All apps are built with [Shiny](https://shiny.posit.co/).
Server and UI modules can be found in `R/`, configuration is stored in 
`inst/config.yml` and loaded via `config::get()`.
Supporting data and text in `inst/`.

### Run locally

Run the app locally on your machine to test that your changes work as expected.

#### Setup

First, install the required packages listed in the DESCRIPTION with 


```r
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
```

Then add an `.Renviron` file to the project root that contains the required 
environment variables.
Copy into it the required variables, which are listed in the `.Renviron.example`.
You can get the values you need from a member of the Data Science team.

#### Run the app

From the project root in R:

```r
run_app()
```

Or run `app.R` directly.

Making selections in the app will cause values to be written to a local json 
file, which will live in your local `params/[development]/` directory.
These scenarios will be selectable and editable in future from your 
locally-run inputs selection app.
They will not be available from the deployed app.

## Project structure

- `R/app_ui.R`: UI layout and controls
- `R/app_server.R`: server logic, scenario validation, routing, and side effects
- `R/upgrade_params.R`: version-to-version parameter migration
- `R/versions.R`: version parsing helpers
- `R/years.R`: baseline/horizon year helpers
- `inst/config.yml`: environment config
- `inst/default_params.json`: baseline params for "Create new from scratch"
- `inst/home.md`: user-facing guidance shown in the app
- `inst/www/`: static assets (map JS and provider geojson)

### Deployment

Deployment is controlled by GitHub Actions in `.github/workflows/`, where:

* pushes to the `main` branch redeploy the app to /nhp/dev/inputs/ for purposes 
of quality assurance
* tagged releases trigger a new deployment to /nhp/vX-Y/inputs/, where 'vX-Y' 
is the current version (note the hyphen)
* manual deployment is possible with `connect-publish-manual.yaml`