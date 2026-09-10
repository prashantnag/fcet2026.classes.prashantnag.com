library(targets)
library(tarchetypes)

# Python environment setup via reticulate
# Run ONCE on a new machine to create the virtual environment:
#   source("_config_python.R")
#
# On every subsequent pipeline run, activate the environment:
if (reticulate::virtualenv_exists("fcet2026_env")) {
  reticulate::use_virtualenv("fcet2026_env", required = TRUE)
}

class_number <- "BMC101"
base_url <- "https://fcet2026.classes.prashantnag.com/"
page_suffix <- ".html"

options(
  tidyverse.quiet = TRUE,
  dplyr.summarise.inform = FALSE
)

tar_option_set(
  packages = c("tibble"),
  format = "rds",
  workspace_on_error = TRUE
)

here_rel <- function(...) {
  fs::path_rel(here::here(...))
}

source("R/tar_calendar.R")

list(
  tar_target(schedule_file, here_rel("data", "schedule.csv"), format = "file"),
  tar_target(schedule_page_data, build_schedule_for_page(schedule_file)),
  tar_target(
    schedule_ical_data,
    build_ical(
      schedule_file,
      base_url,
      page_suffix,
      class_number
    )
  ),
  tar_target(
    schedule_ical_file,
    save_ical(
      schedule_ical_data,
      here_rel("files", "schedule.ics")
    ),
    format = "file"
  ),
  tar_quarto(site, path = ".", quiet = FALSE)
)
