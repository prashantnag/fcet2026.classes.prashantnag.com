options(
  repos = c(
    CRAN = "https://packagemanager.posit.co/cran/latest"
  ),
  renv.config.ppm.enabled = TRUE,
  renv.config.pak.enabled = FALSE
)

if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

if (file.exists("~/.Rprofile")) {
  base::sys.source("~/.Rprofile", envir = environment())
}
