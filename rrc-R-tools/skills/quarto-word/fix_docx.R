#' Fix "unreadable content" and Compatibility Mode in Quarto-rendered Word documents
#'
#' Fixes three issues:
#' 1. flextable stray text nodes ("header1", "body1", etc.) inside <w:tr> elements
#' 2. Duplicate <w:pPr> elements from Pandoc's cross-reference table wrapper
#' 3. Pandoc declares Word 2007 (AppVersion 12.0) causing Compatibility Mode
#'
#' Usage: Rscript fix_docx.R <path-to-docx>
#' Or call fix_docx("path/to/file.docx") from R.

fix_docx <- function(docx_path) {
  if (!file.exists(docx_path)) {
    stop("File not found: ", docx_path)
  }

  # Create a temp directory to work in
  temp_dir <- tempfile("docx_fix_")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  # Unzip the docx
  utils::unzip(docx_path, exdir = temp_dir)

  fixes_applied <- character(0)

  # --- Fix 1 & 2: document.xml ---
  doc_xml_path <- file.path(temp_dir, "word", "document.xml")
  if (!file.exists(doc_xml_path)) {
    stop("document.xml not found in the docx")
  }

  xml_content <- readLines(doc_xml_path, warn = FALSE)
  xml_text <- paste(xml_content, collapse = "\n")
  original <- xml_text

  # Fix 1: Remove stray text nodes in <w:tr> elements (flextable bug)
  xml_text <- gsub("(</w:trPr>)[^<]+(<w:tc>)", "\\1\\2", xml_text)
  xml_text <- gsub("(</w:trPr>)[^<]+(</w:tr>)", "\\1\\2", xml_text)
  xml_text <- gsub("(<w:tr>)[^<]+(<w:trPr>)", "\\1\\2", xml_text)
  xml_text <- gsub("(<w:tr>)[^<]+(<w:tc>)", "\\1\\2", xml_text)

  if (xml_text != original) {
    fixes_applied <- c(fixes_applied, "Removed flextable stray text nodes from <w:tr>")
  }

  # Fix 2: Merge duplicate <w:pPr> elements (Pandoc cross-ref wrapper bug)
  # When Pandoc wraps a flextable in a cross-reference table, the caption <w:p>
  # gets two <w:pPr> blocks. Merge them by removing the boundary.
  before_ppr_fix <- xml_text
  xml_text <- gsub("</w:pPr>\\s*<w:pPr>", "", xml_text)

  if (xml_text != before_ppr_fix) {
    fixes_applied <- c(fixes_applied, "Merged duplicate <w:pPr> elements")
  }

  # Fix 3: Ensure every <w:tc> ends with a <w:p> (OOXML requirement)
  # Pandoc's cross-reference wrapper creates cells where a <w:tbl> or
  # <w:bookmarkEnd> is the last child instead of a required <w:p>.
  before_tc_fix <- xml_text
  xml_text <- gsub("(?<!</w:p>)(</w:tc>)", "<w:p/>\\1", xml_text, perl = TRUE)

  if (xml_text != before_tc_fix) {
    fixes_applied <- c(fixes_applied, "Added missing trailing <w:p> in table cells")
  }

  if (xml_text != original) {
    writeLines(xml_text, doc_xml_path, useBytes = TRUE)
  }

  # --- Fix 4: AppVersion in app.xml (Compatibility Mode) ---
  app_xml_path <- file.path(temp_dir, "docProps", "app.xml")
  if (file.exists(app_xml_path)) {
    app_content <- readLines(app_xml_path, warn = FALSE)
    app_text <- paste(app_content, collapse = "\n")
    app_original <- app_text

    app_text <- gsub("<AppVersion>12\\.0000</AppVersion>",
                     "<AppVersion>16.0000</AppVersion>", app_text)
    app_text <- gsub("<Application>Microsoft Word 12\\.0\\.0</Application>",
                     "<Application>Microsoft Office Word</Application>", app_text)

    if (app_text != app_original) {
      writeLines(app_text, app_xml_path, useBytes = TRUE)
      fixes_applied <- c(fixes_applied, "Updated AppVersion from 12.0 to 16.0")
    }
  }

  # --- Fix 4b: settings.xml - remove old compat flags, add modern compat mode ---
  settings_xml_path <- file.path(temp_dir, "word", "settings.xml")
  if (file.exists(settings_xml_path)) {
    settings_content <- readLines(settings_xml_path, warn = FALSE)
    settings_text <- paste(settings_content, collapse = "\n")
    settings_original <- settings_text

    # Remove old compat flags
    settings_text <- gsub("<w:doNotTrackMoves\\s*/>", "", settings_text)

    # Add w:compat with compatibilityMode=15 (Word 2013+) if not present
    # This is what tells Word to open in modern mode, not Compatibility Mode
    compat_setting <- paste0(
      '<w:compat>',
      '<w:compatSetting w:name="compatibilityMode" ',
      'w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>',
      '</w:compat>'
    )

    if (!grepl("compatibilityMode", settings_text)) {
      # Insert before </w:settings>
      settings_text <- gsub("</w:settings>",
                            paste0(compat_setting, "</w:settings>"),
                            settings_text)
      fixes_applied <- c(fixes_applied, "Added compatibilityMode=15 (Word 2013+)")
    }

    if (settings_text != settings_original) {
      writeLines(settings_text, settings_xml_path, useBytes = TRUE)
      if (grepl("doNotTrackMoves", settings_original)) {
        fixes_applied <- c(fixes_applied, "Removed doNotTrackMoves compat flag")
      }
    }
  }

  # --- Repackage ---
  if (length(fixes_applied) == 0) {
    message("No fixes needed - document is clean.")
    return(invisible(docx_path))
  }

  message("Fixes applied:")
  for (fix in fixes_applied) message("  - ", fix)

  # Re-zip using the zip package (preserves directory structure)
  docx_path <- normalizePath(docx_path, mustWork = TRUE)
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(temp_dir)
  all_files <- list.files(".", recursive = TRUE, all.files = TRUE)

  file.remove(docx_path)
  zip::zip(docx_path, files = all_files)

  message("Fixed docx saved to: ", docx_path)
  invisible(docx_path)
}

# Run from command line (only when called directly, not when source()'d)
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  # When source()'d from another script (e.g., post_render.R), args won't

  # contain a .docx path — so we only run when one is provided.
  if (length(args) >= 1 && grepl("\\.docx$", args[1], ignore.case = TRUE)) {
    fix_docx(args[1])
  }
}
