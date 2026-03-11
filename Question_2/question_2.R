# ---------------------------------------------------
# Script Name: question_2.R
# Purpose: Generate a publication-quality stacked bar chart visualizing the
#          distribution of adverse events by System Organ Class and Severity
#          using the {ggplot2} package.
# Author: Mandy Wu
# Date: March 10, 2026
# Input Data: pharmaverseadam::adae
# Output Data: Question_2/ae_severity_chart.png
# R Version: 4.5.2
# ---------------------------------------------------

## ---- load required libraries ----
# Setup: Uncomment and run the line below if you are missing any dependencies
# install.packages(c("pharmaverseadam", "tidyverse", "gtsummary", "ggplot2", "shiny"))
library(pharmaverseadam)
library(tidyverse)
library(ggplot2)

## ---- input data ----
adae <- pharmaverseadam::adae

# Ensure expected variables exist before proceeding
stopifnot(
  all(c("USUBJID", "AESOC", "AESEV") %in% names(adae))
)

# Review severity levels present in the data
adae %>% count(AESEV) %>% print()

## ---- deduplicate at subject level per SOC and severity ----
# Clinical Logic: Each subject should be counted at most ONCE per severity level within each SOC. A subject who experienced multiple "MILD" events in the same SOC is counted only once for that SOC × Severity combination.
# This is a subject-level summary, not an event-level count.

adae_dedup <- adae %>%
  distinct(USUBJID, AESOC, AESEV)

cat("Total AE records:", nrow(adae), "\n")
cat("Unique Subject x SOC x Severity records:", nrow(adae_dedup), "\n")

## ---- compute subject counts per SOC and severity ----
# Clinical Logic: Count the number of unique subjects for each SOC × Severity combination. This forms the basis of the stacked bar chart.

ae_counts <- adae_dedup %>%
  count(AESOC, AESEV, name = "n_subjects")

# Quick review of the summarized data
cat("\nSubject counts per SOC x Severity (first 10 rows):\n")
head(ae_counts, 10) %>% print()

## ---- compute SOC ordering by total frequency ----
# Clinical Logic: SOCs must be ordered by increasing total subject count
# (across all severity levels). This places the most frequent SOCs at
# the top of the horizontal bar chart for easy visual comparison.
#
# Strategy:
# 1. Calculate total unique subjects per SOC (across all severities)
# 2. Use fct_reorder() to set factor levels by ascending frequency

soc_totals <- ae_counts %>%
  group_by(AESOC) %>%
  summarise(total_subjects = sum(n_subjects), .groups = "drop") %>%
  arrange(total_subjects)

cat("\nSOC totals (ascending order):\n")
soc_totals %>% print(n = Inf)

# Apply factor ordering to ae_counts
# fct_reorder() reorders AESOC levels by the sum of n_subjects (ascending)
ae_counts <- ae_counts %>%
  mutate(AESOC = fct_reorder(AESOC, n_subjects, .fun = sum))

## ---- set severity factor levels and colors ----
# Clinical Logic: Severity levels have a natural clinical order:
# MILD → MODERATE → SEVERE. We enforce this ordering so the stacked
# bars display consistently and the legend reads in clinical order.
#
# Color palette uses a red gradient to intuitively convey increasing severity:
#   MILD = light pink, MODERATE = orange-red, SEVERE = deep red

severity_levels <- c("MILD", "MODERATE", "SEVERE")
severity_colors <- c(
  "MILD"     = "#F4CCCC",
  "MODERATE" = "#E06666",
  "SEVERE"   = "#990000"
)

ae_counts <- ae_counts %>%
  mutate(AESEV = factor(AESEV, levels = severity_levels))

## ---- build publication-quality stacked bar chart ----
# Chart structure:
#   - Y-axis: System Organ Class (AESOC)
#   - X-axis: Count of unique subjects
#   - Fill: Stacked by AE Severity (AESEV)
#   - Ordering: SOCs ordered by increasing total frequency (bottom to top)
#   - Stacking order: MILD (leftmost) → MODERATE → SEVERE (rightmost)
#
# Note: ggplot2 stacks bars in the order of factor levels by default.
# Since severity_levels is defined as c("MILD", "MODERATE", "SEVERE"),
# MILD is placed first (leftmost) and SEVERE is last (rightmost).

ae_severity_plot <- ggplot(
  data = ae_counts,
  aes(x = n_subjects, y = AESOC, fill = AESEV)
) +
  geom_bar(
    stat     = "identity",
    width    = 0.7
  ) +
  scale_fill_manual(
    values = severity_colors,
    name   = "AE Severity"
  ) +
  labs(
    title    = "Adverse Event Distribution by System Organ Class and Severity",
    subtitle = "Number of Unique Subjects per SOC, Stacked by Severity",
    x        = "Number of Unique Subjects",
    y        = "System Organ Class"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    # Title formatting — centred
    plot.title         = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle      = element_text(size = 10, hjust = 0.5, color = "gray40"),
    # Axis title formatting — bolded
    axis.title.x       = element_text(face = "bold", margin = margin(t = 10)),
    axis.title.y       = element_text(face = "bold", margin = margin(r = 10)),
    axis.text.y        = element_text(size = 9),
    # Legend formatting — right side
    legend.position    = "right",
    legend.title       = element_text(face = "bold", size = 10),
    legend.text        = element_text(size = 9),
    # Grid and panel
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank()
  )

## ---- validation checks ----
cat("\n--- Validation Checks ---\n")

# Check 1: Confirm deduplication — no duplicate USUBJID × SOC × Severity
dedup_check <- adae_dedup %>%
  count(USUBJID, AESOC, AESEV) %>%
  filter(n > 1)

if (nrow(dedup_check) == 0) {
  cat("PASSED: No duplicate Subject x SOC x Severity records.\n")
} else {
  warning("FAILED: ", nrow(dedup_check), " duplicate records found!")
}

# Check 2: All severity levels are accounted for
observed_sev <- sort(unique(ae_counts$AESEV))
expected_sev <- sort(severity_levels)

if (all(observed_sev %in% expected_sev)) {
  cat("PASSED: All severity levels are recognized.\n")
} else {
  warning("FAILED: Unexpected severity levels found: ",
          paste(setdiff(observed_sev, expected_sev), collapse = ", "))
}

# Check 3: SOC ordering is correct (ascending by total subjects)
soc_order_check <- levels(ae_counts$AESOC)
cat("\nSOC factor levels (should be ascending by total subjects):\n")
cat(paste(soc_order_check, collapse = "\n"), "\n")

# Check 4: Total subject counts in chart match raw dedup data
chart_total <- sum(ae_counts$n_subjects)
dedup_total <- nrow(adae_dedup)

if (chart_total == dedup_total) {
  cat("\nPASSED: Chart total (", chart_total, ") matches deduplicated data.\n")
} else {
  warning("FAILED: Chart total (", chart_total, ") != dedup total (", dedup_total, ")")
}

## ---- export output ----
# Preview the plot in the viewer for quality check
print(ae_severity_plot)

# Create the folder if it doesn't exist to prevent path errors
if (!dir.exists("Question_2")) {
  dir.create("Question_2")
}

# Save as PNG with publication-quality dimensions
ggsave(
  filename = "Question_2/ae_severity_chart.png",
  plot     = ae_severity_plot,
  width    = 12,
  height   = 8,
  dpi      = 300,
  bg       = "white"
)
