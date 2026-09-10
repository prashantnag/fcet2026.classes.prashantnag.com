# ============================================================
# Python Environment Configuration via reticulate
# ============================================================
# Run this ONCE to set up the Python virtual environment for
# the FCET 2026 course project.
#
# Usage: source("_config_python.R") OR Rscript _config_python.R
# ============================================================

library(reticulate)

env_name <- "fcet2026_env"
python_version <- "3.12"

# --- Step 1: Install Python (if needed via pyenv/reticulate) ---
message("Step 1: Checking/installing Python ", python_version, "...")
tryCatch(
  reticulate::install_python(python_version),
  error = function(e) {
    message("Note: Could not install via reticulate (may already be installed): ", conditionMessage(e))
  }
)

# --- Step 2: Create the virtual environment ---
message("Step 2: Creating virtual environment '", env_name, "'...")
if (!virtualenv_exists(env_name)) {
  virtualenv_create(env_name, python = python_version)
  message("Virtual environment created successfully.")
} else {
  message("Virtual environment '", env_name, "' already exists. Skipping creation.")
}

# --- Step 3: Install required Python packages ---
message("Step 3: Installing required Python packages...")
py_install(
  packages = c(
    "pandas",      # Data manipulation (used in read_excel.py)
    "PyPDF2",      # PDF parsing (used in extract_pdf.py)
    "openpyxl",    # Required by pandas for .xlsx support
    "xlrd"         # Required by pandas for legacy .xls support
  ),
  envname = env_name,
  pip = TRUE
)
message("Python packages installed successfully.")

# --- Step 4: Activate the environment ---
message("Step 4: Activating virtual environment '", env_name, "'...")
use_virtualenv(env_name, required = TRUE)

# --- Verify ---
message("\nSetup complete! Python configuration:")
py_config()
