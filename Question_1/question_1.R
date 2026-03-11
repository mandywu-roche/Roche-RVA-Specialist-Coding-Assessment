# ---------------------------------------------------
# Script Name: question_1.R
# Purpose: Generate a regulatory-compliant Treatment-Emergent Adverse Event (TEAE) summary table using the {gtsummary} package.
# Author: Mandy Wu
# Date: March 10, 2026
# Input Data: pharmaverseadam::adae, pharmaverseadam::adsl
# Output Data: Question_1/teae_summary.html
# R Version: 4.5.2
# ---------------------------------------------------

## ---- load required libraries -----
# Setup: Uncomment and run the line below if you are missing any dependencies 
# install.packages(c("pharmaverseadam", "tidyverse", "gtsummary", "ggplot2", "shiny"))

library(pharmaverseadam)
library(tidyverse)
library(gtsummary)

## ---- input data ----
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# Ensure expected variables exist before proceeding 
stopifnot(
  all(c("USUBJID", "ACTARM") %in% names(adsl)),
  all(c("USUBJID", "ACTARM", "TRTEMFL", "AESOC", "AEDECOD") %in% names(adae))
)

# Review treatment arm distribution in ADSL (denominator source)
adsl %>% count(ACTARM) %>% print()


## ---- filter data to treatment-emergent AEs only ----
# Clinical Logic: Retain only Treatment-Emergent Adverse Events (TEAEs).
# TRTEMFL == "Y" denotes a TEAE.
adae_teae <- adae %>%
  filter(TRTEMFL == "Y")

cat("Total AE records:", nrow(adae), "\n")
cat("TEAE records (TRTEMFL =='Y':", nrow(adae_teae), "\n")


## ---- build "Any TEAE" overall summary row ----
# Clinical Logic: Shows the n(%) of subjects with ANY TEAE across all SOCs.
# Denominator = total subjects per arm from ADSL.

# Strategy:
# 1. Create a binary flag on the full ADSL population
# 2. 1 = subject had at least one TEAE, 0 = no TEAEs
# 3. Summarize with tbl_summary()

any_teae_data <- adsl %>%
  select(USUBJID, ACTARM) %>%
  mutate(
    any_teae = if_else(
      USUBJID %in% unique(adae_teae$USUBJID),
      1L,
      0L
    )
  )

any_teae_tbl <- any_teae_data %>%
  select(ACTARM, any_teae) %>%
  tbl_summary(
    by = ACTARM,
    type = everything() ~ "dichotomous",
    statistic = everything() ~ "{n} ({p}%",
    label = list(any_teae ~ "Treatment Emergent Adverse Events"),
    missing = "no" 
  ) %>%
  bold_labels()

## ---- build subject-level SOC indicators ----
# Clinical Logic: Each SOC row shows n(%) of subjects who had at least one TEAE in that SOC.
# A subject is counted once per SOC regardless of how many PTs they had.
# Denominator = total subjects per arm from ADSL.

# Ensure no duplication: one row per subject per SOC
adae_soc <- adae_teae %>%
  distinct(USUBJID, ACTARM, AESOC)

# Get all unique SOCs (sorted alphabetically)
unique_socs <- sort(unique(adae_soc$AESOC))

# Pivot to wide: one binary column per SOC, one row per subject
soc_wide <- adae_soc %>%
  mutate(flag = 1L) %>%
  pivot_wider(
    id_cols = c(USUBJID, ACTARM),
    names_from = AESOC,
    values_from = flag,
    values_fill = 0L
  ) %>%
  # Right join with ADSL to include subjects with zero TEAEs (denominator)
  right_join(adsl %>% select(USUBJID, ACTARM), by = c("USUBJID", "ACTARM")) %>%
  mutate(across(all_of(unique_socs), ~ replace_na(.x, 0L)))


## ---- build subject-level PT indicators ----
# Clinical Logic: Each PT row shows n(%) of subjects who experienced that specific PT.
# A subject is counted once per SOC/PT combination.

# Ensure no duplication: one row per subject per SOC/PT
adae_soc_pt <- adae_teae %>%
  distinct(USUBJID, ACTARM, AESOC, AEDECOD)
  
# Create a unique key for each SOC/PT preserving the SOC grouping
adae_soc_pt <- adae_soc_pt %>%
  mutate(soc_pt_key = paste0(AESOC, "||", AEDECOD))
unique_soc_pts <- sort(unique(adae_soc_pt$soc_pt_key))

# Pivot to wide: one binary column per SOC/PT, one row per subject
soc_pt_wide <- adae_soc_pt %>%
  mutate(flag = 1L) %>%
  pivot_wider(
    id_cols = c(USUBJID, ACTARM),
    names_from = soc_pt_key,
    values_from = flag,
    values_fill = 0L
  ) %>%
  # Right join with ADSL to include subjects with zero TEAEs (denominator)
  right_join(adsl %>% select(USUBJID, ACTARM), by = c("USUBJID", "ACTARM")) %>%
  mutate(across(all_of(unique_soc_pts), ~ replace_na(.x, 0L)))

# Order PT columns by grouping PTs under their parent SOC
ordered_soc_pt_cols <- character(0)
for(soc in unique_socs) {
  child_pts <- unique_soc_pts[str_starts(unique_soc_pts, fixed(paste0(soc, "||")))]
  ordered_soc_pt_cols <- c(ordered_soc_pt_cols, child_pts)
}


## ---- assemble the nested SOC with PT table ----
# Structure:
# For each SOC:
# 1. A bold SOC header row with its own n(%)
# 2. Indented PT rows under it
# Then stack all SOC groups together with the "Any TEAE" row on top

soc_pt_table_list <- list()
for (soc in unique_socs) {
  # SOC-level row
  soc_col <- soc
  
  soc_row <- soc_wide %>%
    select(ACTARM, all_of(soc_col)) %>%
    tbl_summary(
      by        = ACTARM,
      type      = everything() ~ "dichotomous",
      statistic = everything() ~ "{n} ({p}%)",
      label     = setNames(list(soc), soc_col),
      missing   = "no"
    ) %>%
    bold_labels()
  
  # PT-level rows under this SOC
  child_pt_cols <- ordered_soc_pt_cols[
    str_starts(ordered_soc_pt_cols, fixed(paste0(soc, "||")))
  ]
  
  if (length(child_pt_cols) > 0) {
    # Indent PT labels using non-breaking spaces for reliable HTML rendering
    child_labels <- setNames(
      as.list(
        paste0("\U00A0\U00A0\U00A0\U00A0", str_extract(child_pt_cols, "(?<=\\|\\|).+$"))
      ),
      child_pt_cols
    )
    
    pt_rows <- soc_pt_wide %>%
      select(ACTARM, all_of(child_pt_cols)) %>%
      tbl_summary(
        by        = ACTARM,
        type      = everything() ~ "dichotomous",
        statistic = everything() ~ "{n} ({p}%)",
        label     = child_labels,
        missing   = "no"
      )
    
    soc_pt_table_list <- append(soc_pt_table_list, list(soc_row, pt_rows))
  } else {
    soc_pt_table_list <- append(soc_pt_table_list, list(soc_row))
  }
}

# Final assembly with "Any TEAE" as the first row, then all SOC/PT groups
all_tables <- c(list(any_teae_tbl), soc_pt_table_list)

teae_summary_tbl <- tbl_stack(
  tbls = all_tables,
  quiet = TRUE
)

# Rename column header
teae_summary_tbl <- teae_summary_tbl %>%
  modify_header(label ~ "**System Organ Class / Preferred Term**")


## ---- validation checks ----
cat("\n--- Validation Checks ---\n")

# Check 1: Subject counts per arm match ADSL
cat("ADSL subject counts by treatment arm:\n")
adsl %>% select(USUBJID, ACTARM) %>% count(ACTARM) %>% print()

# Check 2: TEAE subject counts do not exceed arm totals
cat("\nSubjects with at least one TEAE by treatment arm:\n")
adae_teae %>%
  distinct(USUBJID, ACTARM) %>%
  count(ACTARM) %>%
  print()

# Check 3: No subject appears in multiple treatment arms
multi_arm <- adae_teae %>%
  distinct(USUBJID, ACTARM) %>%
  count(USUBJID) %>%
  filter(n > 1)

if (nrow(multi_arm) == 0) {
  cat("\nPASSED: No subjects in multiple treatment arms.\n")
} else {
  warning("FAILED: ", nrow(multi_arm), " subject(s) in multiple arms!")
}

# Check 4: Spot check top 5 most frequent SOCs
cat("\nTop 5 SOCs by unique subject count:\n")
adae_teae %>%
  distinct(USUBJID, ACTARM, AESOC) %>%
  count(ACTARM, AESOC, name = "n_subjects") %>%
  arrange(desc(n_subjects)) %>%
  head(5) %>%
  print()

# Check 5: Verify merged datasets preserve full ADSL subject count
n_adsl <- n_distinct(adsl$USUBJID)

n_soc_wide <- n_distinct(soc_wide$USUBJID)
if (n_soc_wide == n_adsl) {
  cat("\nPASSED: SOC wide dataset subject count matches ADSL (", n_adsl, "subjects).\n")
} else {
  warning("FAILED: SOC wide has ", n_soc_wide, " but ADSL has ", n_adsl, " subjects.")
}

n_pt_wide <- n_distinct(soc_pt_wide$USUBJID)
if (n_pt_wide == n_adsl) {
  cat("PASSED: PT wide dataset subject count matches ADSL (", n_adsl, "subjects).\n")
} else {
  warning("FAILED: PT wide has ", n_pt_wide, " but ADSL has ", n_adsl, " subjects.")
}

## ---- export output ----

# Preview output in the viewer for quality check
print(teae_summary_tbl)

# Export output
# Create the folder if it doesn't exist to prevent path errors
if (!dir.exists("Question_1")) {
  dir.create("Question_1")
}

# Convert to gt, apply final styling, and save as HTML
teae_gt <- gtsummary::as_gt(teae_summary_tbl)

# Apply full-row bold styling to SOC and TEAE header rows
gt_data <- teae_gt[["_data"]]

bold_row_indices <- which(
  gt_data$label %in% unique_socs |
    gt_data$label == "Treatment Emergent Adverse Events"
)

if (length(bold_row_indices) > 0) {
  teae_gt <- teae_gt %>%
    gt::tab_style(
      style     = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(
        rows = bold_row_indices
      )
    )
}

# Add table title and save to folder
teae_gt %>%
  gt::tab_header(
    title    = "Table 1: Summary of Treatment-Emergent Adverse Events",
    subtitle = "Safety Population — by System Organ Class and Preferred Term"
  ) %>%
  gt::gtsave(file = "Question_1/teae_summary.html")

# Final check: Verify that HTML output was saved to Question_1 folder
cat("\nHTML output saved to: Question_1/teae_summary.html\n")
