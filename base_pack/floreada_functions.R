# Floreada CSV Processing Functions
# Adapted for Attune NxT with FLoreada software
# Replaces bears01::flowjo2df() functionality

library(readr)
library(dplyr)
library(stringr)
library(data.table)

#' Read metadata from keywords.txt file
#' @param keywords_file Path to keywords.txt file
#' @return Named list of metadata
read_keywords <- function(keywords_file) {
  if (!file.exists(keywords_file)) {
    warning(paste("Keywords file not found:", keywords_file))
    return(list())
  }
  
  lines <- readLines(keywords_file, warn = FALSE)
  metadata <- list()
  
  for (line in lines) {
    # Parse lines like "#FLOWRATE" or "$DATE"
    if (grepl("^[#$]", line)) {
      parts <- strsplit(line, "\n")[[1]]
      for (part in parts) {
        if (grepl("^[#$]\\w+", part)) {
          # Split on first comma or newline
          key_val <- strsplit(part, "\n")[[1]][1]
          
          # Check if there's a next line with the value
          idx <- which(lines == part)
          if (idx < length(lines)) {
            key <- sub("^[#$]", "", part)
            val <- lines[idx + 1]
            metadata[[key]] <- val
          }
        }
      }
    }
  }
  
  # Alternative parsing: look for key-value on same line
  for (line in lines) {
    # Look for patterns like $KEY or #KEY followed by value
    if (grepl("^[$#]", line) && !grepl("^[$#]\\w+$", line)) {
      # Has value on same line after comma or space
      parts <- unlist(strsplit(line, ","))
      if (length(parts) == 2) {
        key <- gsub("^[$#]", "", parts[1])
        val <- parts[2]
        metadata[[key]] <- val
      }
    }
  }
  
  return(metadata)
}

#' Process a single Floreada CSV file
#' @param csv_file Path to the CSV file
#' @param keywords_file Path to keywords.txt file (optional)
#' @param platesetup Data frame with plate setup information
#' @return Data frame with flow data merged with metadata
floreada2df <- function(csv_file, keywords_file = NULL, platesetup = NULL) {
  
  # Read the CSV (FLoreada format has headers on first line, no metadata)
  flowdata <- fread(csv_file, header = TRUE)
  
  # Extract well ID from filename
  # Assumes filename format like "259.fcs.csv" or similar
  filename <- basename(csv_file)
  file_id <- sub("\\.fcs.*$", "", filename)
  file_id <- sub("\\.csv$", "", file_id)
  
  # Initialize metadata list
  metadata <- list(
    File = filename,
    FileID = file_id,
    WellID = NA,
    Date = NA,
    Operator = NA,
    Experiment = NA,
    TotalEvents = nrow(flowdata),
    FlowRate = NA,
    Volume = NA
  )
  
  # Read keywords if provided
  if (!is.null(keywords_file) && file.exists(keywords_file)) {
    kw <- read_keywords(keywords_file)
    
    # Map common keywords to metadata
    if ("WELLID" %in% names(kw)) metadata$WellID <- kw$WELLID
    if ("DATE" %in% names(kw)) metadata$Date <- kw$DATE
    if ("OP" %in% names(kw)) metadata$Operator <- kw$OP
    if ("PROJ" %in% names(kw)) metadata$Experiment <- kw$PROJ
    if ("EXP" %in% names(kw)) metadata$Experiment <- kw$EXP
    if ("TOT" %in% names(kw)) metadata$TotalEvents <- as.numeric(kw$TOT)
    if ("FLOWRATE" %in% names(kw)) metadata$FlowRate <- as.numeric(kw$FLOWRATE)
    if ("VOL" %in% names(kw)) metadata$Volume <- as.numeric(kw$VOL)
    if ("FIL" %in% names(kw)) {
      # Use FIL as file identifier if available
      metadata$FileID <- sub("\\.fcs$", "", kw$FIL)
    }
  }
  
  # Try to extract well ID from filename if not in keywords
  if (is.na(metadata$WellID)) {
    # Look for patterns like _A1_ or -B2- or A1. etc
    well_match <- str_extract(filename, "[A-H][0-9]{1,2}")
    if (!is.na(well_match)) {
      metadata$WellID <- well_match
    }
  }
  
  # Add metadata columns to flow data
  for (col in names(metadata)) {
    flowdata[[col]] <- metadata[[col]]
  }
  
  # Convert ID columns to character to ensure consistent type for merging
  if ("FileID" %in% names(flowdata)) {
    flowdata$FileID <- as.character(flowdata$FileID)
  }
  if ("WellID" %in% names(flowdata)) {
    flowdata$WellID <- as.character(flowdata$WellID)
  }
  
  # Merge with plate setup if provided
  if (!is.null(platesetup)) {
    # Convert platesetup ID columns to character as well
    if ("FileID" %in% names(platesetup)) {
      platesetup$FileID <- as.character(platesetup$FileID)
    }
    if ("WellID" %in% names(platesetup)) {
      platesetup$WellID <- as.character(platesetup$WellID)
    }
    
    # Determine which column to merge on
    merge_col <- NULL
    if ("WellID" %in% names(platesetup) && !is.na(metadata$WellID)) {
      merge_col <- "WellID"
    } else if ("FileID" %in% names(platesetup)) {
      merge_col <- "FileID"
    } else if ("File" %in% names(platesetup)) {
      merge_col <- "File"
    }
    
    if (!is.null(merge_col)) {
      flowdata <- left_join(flowdata, platesetup, by = merge_col)
    } else {
      warning("Could not find matching column to merge with platesetup")
    }
  }
  
  return(flowdata)
}

#' Process all CSV files in a directory
#' @param dir Directory containing CSV files
#' @param csvstring Pattern to match CSV files (e.g., "_P3.csv")
#' @param platesetup_file Path to platesetup.txt file
#' @param keywords_dir Directory containing keywords.txt files (default: same as CSV dir)
#' @param fileout Output filename for combined data
#' @return Combined data frame
processFloreadaExportDir <- function(dir, 
                                      csvstring = ".csv", 
                                      platesetup_file = "platesetup.txt",
                                      keywords_dir = NULL,
                                      fileout = "combined_data.txt") {
  
  # Set keywords directory to same as CSV directory if not specified
  if (is.null(keywords_dir)) {
    keywords_dir <- dir
  }
  
  # Read plate setup
  platesetup_path <- file.path(dir, platesetup_file)
  if (file.exists(platesetup_path)) {
    platesetup <- fread(platesetup_path, header = TRUE)
    message(paste("Loaded plate setup with", nrow(platesetup), "rows"))
    
    # Convert ID columns to character to prevent type mismatch during merge
    if ("FileID" %in% names(platesetup)) {
      platesetup$FileID <- as.character(platesetup$FileID)
    }
    if ("WellID" %in% names(platesetup)) {
      platesetup$WellID <- as.character(platesetup$WellID)
    }
    
  } else {
    warning(paste("Plate setup file not found:", platesetup_path))
    platesetup <- NULL
  }
  
  # Find all CSV files matching pattern
  csv_files <- list.files(dir, pattern = csvstring, full.names = TRUE)
  message(paste("Found", length(csv_files), "CSV files matching pattern:", csvstring))
  
  if (length(csv_files) == 0) {
    stop("No CSV files found matching pattern")
  }
  
  # Process each CSV file
  all_data <- list()
  
  for (i in seq_along(csv_files)) {
    csv_file <- csv_files[i]
    message(paste("Processing file", i, "of", length(csv_files), ":", basename(csv_file)))
    
    # Look for corresponding keywords file
    # Try multiple naming conventions
    base_name <- sub("\\.csv$", "", basename(csv_file))
    base_name <- sub("\\.fcs.*$", "", base_name)
    
    # Extract file prefix (e.g., "259" from "259_VP64pos.csv")
    file_prefix <- sub("_.*$", "", base_name)
    
    keywords_candidates <- c(
      file.path(keywords_dir, paste0(base_name, "_keywords.txt")),  # 259_VP64pos_keywords.txt
      file.path(keywords_dir, paste0(file_prefix, "_keywords.txt")), # 259_keywords.txt
      file.path(keywords_dir, paste0(base_name, ".txt")),            # 259_VP64pos.txt
      file.path(keywords_dir, paste0(file_prefix, ".txt")),          # 259.txt
      file.path(keywords_dir, "keywords.txt")                        # Generic keywords file
    )
    
    keywords_file <- NULL
    for (kf in keywords_candidates) {
      if (file.exists(kf)) {
        keywords_file <- kf
        break
      }
    }
    
    if (!is.null(keywords_file)) {
      message(paste("  Using keywords file:", basename(keywords_file)))
    }
    
    # Process this file
    tryCatch({
      file_data <- floreada2df(csv_file, keywords_file, platesetup)
      all_data[[i]] <- file_data
    }, error = function(e) {
      warning(paste("Error processing", basename(csv_file), ":", e$message))
    })
  }
  
  # Combine all data using bind_rows (handles different columns gracefully)
  message("Combining all data...")
  combined_data <- bind_rows(all_data)
  message(paste("Combined data has", nrow(combined_data), "rows and", ncol(combined_data), "columns"))
  
  # Write output
  output_path <- file.path(dir, fileout)
  fwrite(combined_data, output_path, sep = "\t", quote = FALSE)
  message(paste("Wrote output to:", output_path))
  
  return(combined_data)
}

#' Alternative function that expects one keywords.txt per CSV
#' For cases where you export keywords separately for each FCS file
processFloreadaExportDir_matched <- function(dir, 
                                              csvstring = ".csv",
                                              keywords_pattern = "_keywords.txt",
                                              platesetup_file = "platesetup.txt",
                                              fileout = "combined_data.txt") {
  
  # Read plate setup
  platesetup_path <- file.path(dir, platesetup_file)
  if (file.exists(platesetup_path)) {
    platesetup <- fread(platesetup_path, header = TRUE)
    message(paste("Loaded plate setup with", nrow(platesetup), "rows"))
    
    # Convert ID columns to character to prevent type mismatch during merge
    if ("FileID" %in% names(platesetup)) {
      platesetup$FileID <- as.character(platesetup$FileID)
    }
    if ("WellID" %in% names(platesetup)) {
      platesetup$WellID <- as.character(platesetup$WellID)
    }
    
  } else {
    warning(paste("Plate setup file not found:", platesetup_path))
    platesetup <- NULL
  }
  
  # Find all CSV files matching pattern
  csv_files <- list.files(dir, pattern = csvstring, full.names = TRUE)
  message(paste("Found", length(csv_files), "CSV files"))
  
  if (length(csv_files) == 0) {
    stop("No CSV files found")
  }
  
  # Process each CSV file with its matched keywords file
  all_data <- list()
  
  for (i in seq_along(csv_files)) {
    csv_file <- csv_files[i]
    message(paste("Processing file", i, "of", length(csv_files), ":", basename(csv_file)))
    
    # Look for matched keywords file
    base_csv <- sub("\\.csv$", "", csv_file)
    keywords_file <- paste0(base_csv, keywords_pattern)
    
    if (!file.exists(keywords_file)) {
      # Try without .fcs extension
      base_csv <- sub("\\.fcs.*$", "", csv_file)
      keywords_file <- paste0(base_csv, keywords_pattern)
    }
    
    if (!file.exists(keywords_file)) {
      warning(paste("No keywords file found for:", basename(csv_file)))
      keywords_file <- NULL
    } else {
      message(paste("  Using keywords file:", basename(keywords_file)))
    }
    
    # Process this file
    tryCatch({
      file_data <- floreada2df(csv_file, keywords_file, platesetup)
      all_data[[i]] <- file_data
    }, error = function(e) {
      warning(paste("Error processing", basename(csv_file), ":", e$message))
    })
  }
  
  # Combine all data
  message("Combining all data...")
  combined_data <- bind_rows(all_data)
  message(paste("Combined data has", nrow(combined_data), "rows and", ncol(combined_data), "columns"))
  
  # Write output
  output_path <- file.path(dir, fileout)
  fwrite(combined_data, output_path, sep = "\t", quote = FALSE)
  message(paste("Wrote output to:", output_path))
  
  return(combined_data)
}
