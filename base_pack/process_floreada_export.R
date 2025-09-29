# FLoreada Export Processing Script
# Updated version for Attune NxT with FLoreada software
# Replaces 2021-10-24_processflowjoexport.R

# Set your parent directory
parentdir <- '/path/to/your/experiment/folder'

setwd(parentdir)

# Source the FLoreada functions
source('floreada_functions.R')  # Or use full path if not in same directory

# Process all CSV files in the floreadaexport directory
# This will:
# 1. Read all CSV files matching the pattern
# 2. Look for keywords.txt file(s) for metadata
# 3. Merge with platesetup.txt for experimental annotations
# 4. Combine all data into one table

singlets <- processFloreadaExportDir(
  dir = file.path(parentdir, 'floreadaexport'),
  csvstring = '_P3.csv',  # Pattern to match your gate
  platesetup_file = 'platesetup.txt',
  fileout = 'P3_combodf.txt'
)

GFPpos <- processFloreadaExportDir(
  dir = file.path(parentdir, 'floreadaexport'),
  csvstring = '_GFPpos.csv', # Pattern to match your gate
  platesetup_file = 'platesetup.txt',
  fileout = 'GFPpos_combodf.txt'
)

# If you have separate keywords files for each FCS file, use this instead:
# singlets <- processFloreadaExportDir_matched(
#   dir = file.path(parentdir, 'floreadaexport'),
#   csvstring = '.csv',
#   keywords_pattern = '_keywords.txt',  # Suffix for keywords files
#   platesetup_file = 'platesetup.txt',
#   fileout = 'P3_combodf.txt'
# )
