# Quick Start Guide - Floreada Flow Processing

## 5-Minute Setup

### 1. Copy Files
Download `base_pack` and copy these files to your experiment folder:
- `floreada_functions.R` - Core functions
- `process_floreada_export.R` - Main script  
- `platesetup.txt` - Template (customize this!)

### 2. Create Your Folder Structure
```
your_experiment/
├── floreadaexport/
│   ├── [your CSV files here]
│   ├── keywords.txt
│   └── platesetup.txt
├── floreada_functions.R
└── process_floreada_export.R
```

### 3. Edit platesetup.txt 

Open Excel or your Text Editor, edit the template / create a table like this, then save as tab-delimited text:

| FileID | Sample | Spacer | Backbone | gSZID | crRNAMOI | Stain | CellType |
|--------|--------|--------|----------|-------|----------|-------|----------|
| "259" | PC3_NT | None-No_guide | CRISPRa-VP64 | pSZ002 | 0.5 | GFP_only | PC3 |
| "260" | PC3_NT | None-No_guide | CRISPRa-VPR | pSZ003 | 0.5 | GFP_only | PC3 |

**Important**: First column should be `FileID`, `WellID`, or `File` depending on how your files are named. If you are using FileID, remember to put " " around the IDs. See `platesetup_instructions.txt` for more information.

### 4. Create keywords.txt

Copy FCS keywords from your Floreada interface: 
- Right-click one FCS file
- View Keywords
- Copy text to keywords.txt
- Save in floreadaexport folder

### 5. Edit process_floreada_export.R

Change these two lines:
```r
parentdir <- '/path/to/your/experiment'  # Your folder path
csvstring = '_P3.csv'  # Your file pattern
```

### 6. Run It!
```r
source('process_floreada_export.R')
```

### 7. Check Output
Look for `P3_combodf.txt` in floreadaexport folder.

## What You Get

A combined table with:
- ✓ All your flow data (all channels)
- ✓ Metadata from keywords.txt
- ✓ Experimental variables from platesetup.txt
- ✓ Ready for analysis with your existing scripts

## Common Issues

**"No CSV files found"**
→ Check your csvstring pattern matches your files

**"Keywords file not found"**  
→ Make sure keywords.txt is in floreadaexport folder

**"Could not find matching column"**
→ First column of platesetup.txt must be FileID, WellID, or File

## Next Steps

Use the output file just like before with `_analysis.R`:
```r
library(data.table)
p3dt <- fread('floreadaexport/P3_combodf.txt')

# Your existing analysis code works here!
filter(p3dt, `BL1-A` > 0)
```

## Need More Help?
- Read SUMMARY.txt (Upcoming)
- Read platesetup_instructions.txt for platesetup info
