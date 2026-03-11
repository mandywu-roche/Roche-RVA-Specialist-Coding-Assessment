# Roche-RVA-Specialist-Coding-Assessment

Submission for the Roche RVA Specialist Coding Assessment: Data Manipulation with `{tidyverse}`, clinical reporting with `{gtsummary}`, and interactive application development using R Shiny


RVA Specialist Coding Assessment

Roche PD Data Science & Analytics

Applicant: Mandy Wu 

Date: March 10, 2026

R Version: 4.5.2 on Posit Cloud



📌 Overview

This repository contains my submission for the RVA Specialist Coding Assessment. It demonstrates proficiency in clinical data manipulation, regulatory-compliant reporting, and interactive dashboard development using the `ADSL` (Subject-Level) and `ADAE` (Adverse Event) datasets from the `{pharmaverseadam}` package. 

Throughout this assessment, I prioritized pharmaceutical industry best practices, including explicit namespacing, defensive programming, and comprehensive clinical-logic documentation.



🗂️ Repository Structure

This assessment is structured into three distinct folders corresponding to each of the three questions given:

Question_1/: TEAE Summary Table

Generates a regulatory-compliant Treatment-Emergent Adverse Event (TEAE) summary table. 

* `question_1.R`: Utilizes `{gtsummary}` and `{tidyverse}` to filter for TEAEs (`TRTEMFL == "Y"`) and aggregate subject counts and percentages by System Organ Class (SOC) and Preferred Term (PT), grouped by Treatment Arm (`ACTARM`). Denominators are derived from ADSL which is the subject-level source of truth for the population `N`.
* `teae_summary.html`: The exported HTML table output.

Question_2/: AE Severity Visualization

Develops a publication-quality visualization of adverse event (AE) distributions.

* `question_2.R`: Utilizes `{ggplot2}` to construct a stacked horizontal bar chart. Aggregates unique subjects per System Organ Class (SOC) per Severity (`AESEV`), ensuring each subject is counted at most once per severity level within each SOC. SOCs are ordered by ascending total frequency. 
* `ae_severity_chart.png`: The exported publication-quality PNG plot.

Question_3/: Interactive R Shiny Application

Integrates the AE visualization from `question_2.R` into a dynamic interactive dashboard.

* `question_3.R`: Contains the UI and Server logic for a `{shiny}` application that allows users to filter the AE severity chart dynamically by Treatment Arm ('ACTARM'). The plot updates reactively based on user selection.



⚙️ Setup & Execution

Prerequisites: Ensure you have R (version 4.2.0 or higher) installed. The following packages are required:
```r
install.packages(c("pharmaverseadam", "tidyverse", "gtsummary", "ggplot2", "shiny", "gt"))
```

Running the code:

* Clone this repository to your local machine or Posit Cloud environment.
* Execute `question_1.R` and `question_2.R` sequentially. Outputs will be saved to their respective directories.
* Open `question_3.R` and click "Run App" in RStudio to launch the interactive dashboard.



💡 Methodology Used & Best Practices

To ensure the codebase is robust, reproducible, and ready for a clinical reporting environment, the following practices were implemented:

* Traceability: Script headers include metadata defining inputs, outputs, and purpose.
* Explicit Namespacing: Key functions are called with their package prefixes to prevent masking conflicts.
* Defensive Programming: Implementation of `stopifnot()` to validate data presence before execution to prevent silent failures.
* Clinical Validation Checks: Numbered validation checks in `question_1.R` and `question_2.R` verify subject counts, deduplication, and denominator integrity.
* Documentation: Inline comments explain the clinical or business logic behind the R operations.



📦 Data Sources

This assessment uses datasets from the `{pharmaverseadam}` package:
* `ADSL` - Analysis Dataset Subject Level: one row per subject, defines the safety population and treatment arm assignments
* `ADAE` - Analysis Dataset Adverse Event: one row per adverse event, contains SOC, Preferred Term, severity, and treatment-emergent flags 
