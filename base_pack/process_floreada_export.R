# ============================================================================
# FLoreada Export Processing Script - TEMPLATE
# ============================================================================
# This script processes flow cytometry CSV files exported from FLoreada software
# and combines them with metadata and experimental annotations.
#
# INSTRUCTIONS:
# 1. Update the paths in the SETUP section below
# 2. Update the csvstring patterns to match YOUR file naming
# 3. Add or remove processing blocks as needed for your gates
# 4. Run the script!
# ============================================================================

# ============================================================================
# SETUP - UPDATE THESE PATHS
# ============================================================================

# Set your experiment directory (CHANGE THIS!)
parentdir <- '/path/to/your/experiment/folder'

# Set working directory
setwd(parentdir)

# Load required libraries
library(data.table)
library(dplyr)

# Source the FLoreada functions (should be in same directory)
source('floreada_functions.R')

# ============================================================================
# CONFIGURE YOUR EXPORT FOLDER NAME (CHANGE THIS!)
# ============================================================================

export_folder <- 'floreadaexport'  # Name of folder containing your CSV files

# ============================================================================
# PROCESS YOUR GATES
# ============================================================================
# Each block below processes one gate type and creates one combined file
# containing ALL samples that match the csvstring pattern.
#
# CUSTOMIZE THE BLOCKS BELOW:
# - Change csvstring to match YOUR file naming convention
# - Change fileout to desired output filename
# - Add or remove blocks as needed for your gates
# ============================================================================

# Example gate 1: Process all ungated cells
# CUSTOMIZE: Change '_all.csv' to match your files (e.g., '_singlets.csv', '_P1.csv')
gate1 <- processFloreadaExportDir(
  dir = file.path(parentdir, export_folder),
  csvstring = '_all.csv',              # CHANGE THIS to match your files
  platesetup_file = 'platesetup.txt',
  fileout = 'gate1_combodf.txt'        # CHANGE THIS to desired output name
)

# Example gate 2: Process first gated population
# CUSTOMIZE: Change '_PC3.csv' to match your files (e.g., '_P2.csv', '_live.csv')
gate2 <- processFloreadaExportDir(
  dir = file.path(parentdir, export_folder),
  csvstring = '_PC3.csv',              # CHANGE THIS to match your files
  platesetup_file = 'platesetup.txt',
  fileout = 'gate2_combodf.txt'        # CHANGE THIS to desired output name
)

# Example gate 3: Process second gated population
# CUSTOMIZE: Change '_BFP.csv' to match your files (e.g., '_P3.csv', '_GFPpos.csv')
gate3 <- processFloreadaExportDir(
  dir = file.path(parentdir, export_folder),
  csvstring = '_BFP.csv',              # CHANGE THIS to match your files
  platesetup_file = 'platesetup.txt',
  fileout = 'gate3_combodf.txt'        # CHANGE THIS to desired output name
)

# ============================================================================
# ADD MORE GATES AS NEEDED
# ============================================================================
# Copy the block above and customize for additional gates
# Example:
# gate4 <- processFloreadaExportDir(
#   dir = file.path(parentdir, export_folder),
#   csvstring = '_yourgate.csv',
#   platesetup_file = 'platesetup.txt',
#   fileout = 'gate4_combodf.txt'
# )

# ============================================================================
# CREATE MASTER COMBINED FILE (OPTIONAL)
# ============================================================================
# Combines all gates into one master file
# CUSTOMIZE: Add or remove gate variables to match what you processed above

masterdf <- bind_rows(gate1, gate2, gate3)  # Add gate4, gate5, etc. if needed

fwrite(masterdf, 
       file.path(parentdir, export_folder, 'masterdf.txt'),
       sep = '\t', 
       quote = FALSE)

# ============================================================================
# VERIFICATION
# ============================================================================

print(paste("Master file created with", nrow(masterdf), "total rows"))
print("Gates in master file:")
print(table(masterdf$csvstring))

print("\nSamples in master file:")
print(table(masterdf$FileID))

# ============================================================================
# NOTES ON FILE NAMING
# ============================================================================
# The csvstring pattern matches multiple files. For example:
#   csvstring = '_all.csv' matches:
#     - 259_all.csv
#     - 260_all.csv
#     - 261_all.csv
#   All matched files are combined into ONE output file.
#
# Common naming patterns:
#   '_P1.csv', '_P2.csv', '_P3.csv'  (if using gate names)
#   '_singlets.csv', '_live.csv', '_GFPpos.csv'  (if using descriptive names)
#   '_all.csv', '_gated.csv', '_final.csv'  (if using custom names)
#
# Choose patterns that match YOUR exported file names!
# ============================================================================