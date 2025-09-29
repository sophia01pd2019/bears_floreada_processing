# FLoreada Export Processing Script
# Updated version for Attune NxT with FLoreada software
# Replaces 2021-10-24_processflowjoexport.R

# Set your parent directory
parentdir <- '/Users/sophia01px2019/Downloads/bears_floreada_processing/worked_example/test_floreadaexport'

setwd(parentdir)

# Source the FLoreada functions
source('floreada_functions.R')  # Or use full path if not in same directory

# Process all CSV files in the floreadaexport directory
# This will:
# 1. Read all CSV files matching the pattern
# 2. Look for keywords.txt file(s) for metadata
# 3. Merge with platesetup.txt for experimental annotations
# 4. Combine all data into one table

# I renamed the event exports from Floreada: 
# Original:               Rename to:
#   events-259.csv    →    259_all.csv
# events-PC3.csv    →    259_PC3.csv
# events-+.csv  →    259_BFP.csv

# Process all ungated cells
all_cells <- processFloreadaExportDir(
  dir = file.path(parentdir, 'floreadexport_092925'),
  csvstring = '_all.csv',      # ← Matches: 259_all.csv
  platesetup_file = 'platesetup.txt',
  fileout = 'all_cells_combodf.txt'
)

# Process PC3-gated cells
pc3_gated <- processFloreadaExportDir(
  dir = file.path(parentdir, 'floreadexport_092925'),
  csvstring = '_PC3.csv',      # ← Matches: 259_PC3.csv
  platesetup_file = 'platesetup.txt',
  fileout = 'PC3_combodf.txt'
)

# Process BFP-gated cells
gfp_positive <- processFloreadaExportDir(
  dir = file.path(parentdir, 'floreadexport_092925'),
  csvstring = '_BFP.csv',  # ← Matches: 259_BFP.csv
  platesetup_file = 'platesetup.txt',
  fileout = 'BFP_combodf.txt'
)

masterdf <- bind_rows(all_cells, pc3_gated, gfp_positive)

fwrite(masterdf, 
       file.path(parentdir, 'floreadexport_092925/masterdf.txt'),
       sep = '\t', 
       quote = FALSE)

print(paste("Master file created with", nrow(masterdf), "total rows"))
print(table(masterdf$csvstring))  # Shows which gates are in the master file

# If you add more samples (260, 261, etc.) with the same naming pattern:
#   259_all.csv, 260_all.csv, 261_all.csv     ← All matched by '_all.csv'
# 259_PC3.csv, 260_PC3.csv, 261_PC3.csv     ← All matched by '_PC3.csv'
# 259_BFP.csv, 260_BFP.csv, ...     ← All matched by '_BFP.csv'
# The same csvstring will process all files at once!