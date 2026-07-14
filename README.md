# nhp_inputs_selection_app

A Shiny app that sits in front of the NHP Inputs app and helps users:

- select an existing scenario
- create a new scenario (from scratch or from an existing one)
- choose the NHP Inputs model version to open
- launch into the correct version of the Inputs app with the selected scenario parameters

In practice, this app is the entry point for managing scenario JSON files and routing users to the right NHP Inputs app version.

## What this app does

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
- blocks upgrades for unsupported legacy scenarios (for example older baseline years or certain NDG variants)

## Relationship to nhp_inputs

This project does not replace the main Inputs app. It prepares and routes users into it.

- This app writes/loads parameter files.
- The main `nhp_inputs` app consumes those parameters.
- The app URL template is environment specific (see configuration below).

## Configuration

Configuration is stored in `inst/config.yml` and loaded via `config::get()`.

Current keys:

- `app_url`: target URL pattern for opening the Inputs app
- `params_data_path`: root location where params and temp files are read/written

Environments in this repo:

- `default`
- `development`
- `production`

`production.app_url` uses a version placeholder (for example `/nhp/{version}/inputs/`), which is filled from the selected model version.

## Parameter file layout

Parameters are stored under:

- `{params_data_path}/params/{user}/{dataset}/{scenario}.json`

Temporary launch files are created under:

- `{params_data_path}/tmp/`

The temporary filename is passed to the target Inputs app as a query string parameter.

## Scenario versioning and upgrades

When a saved scenario is loaded:

- the original version is captured as metadata (`prior_app_version`)
- upgrade steps are applied to move parameters to the latest supported structure
- UI warnings are shown for meaningful breaking/behavioural changes

Upgrade logic is implemented in `R/upgrade_params.R`.

## Run locally

### Prerequisites

- R >= 4.4.0
- Package dependencies listed in `DESCRIPTION`

### Start the app

From the project root in R:

```r
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
run_app()
```

Or run `app.R` directly.

## Project structure (high level)

- `R/app_ui.R`: UI layout and controls
- `R/app_server.R`: server logic, scenario validation, routing, and side effects
- `R/upgrade_params.R`: version-to-version parameter migration
- `R/versions.R`: version parsing helpers
- `R/years.R`: baseline/horizon year helpers
- `inst/config.yml`: environment config
- `inst/default_params.json`: baseline params for "Create new from scratch"
- `inst/home.md`: user-facing guidance shown in the app
- `inst/www/`: static assets (map JS and provider geojson)

## Deployment notes

The app is designed for Posit Connect-style environments and uses runtime context (for example user and group information) to control:

- provider visibility
- advanced options visibility
- editable model version/user scope

Deployment helper scripts are in `dev/`.

## Maintainers

See `DESCRIPTION` for package authors and maintainers.
