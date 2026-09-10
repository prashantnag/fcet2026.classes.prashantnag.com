library(reticulate)

cat("--- Activating virtual environment ---\n")
use_virtualenv("fcet2026_env", required = TRUE)

cat("\n--- Python configuration ---\n")
py_config()

cat("\n--- Verifying package imports ---\n")
py_run_string("
import pandas
import PyPDF2
import openpyxl
import xlrd

print('pandas   :', pandas.__version__)
print('PyPDF2   :', PyPDF2.__version__)
print('openpyxl :', openpyxl.__version__)
print('xlrd     :', xlrd.__version__)
print()
print('All packages imported successfully!')
")
