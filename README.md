# Roche-RVA-Specialist-Coding-Assessment

Submission for the Roche RVA Specialist Coding Assessment: Data Manipulation with {tidyverse}, clinical reporting with {gtsummary}, and interactive application development using R Shiny


RVA Specialist Coding Assessment

Roche PD Data Science & Analytics

Applicant: Mandy Wu 

Date: March 10, 2026

R Version: 4.2.0 on Postit Cloud


📌 Overview

This repository contains my submission for the RVA Specialist Coding Assessment. It demonstrates my proficiency in clinical data manipulation, regulatory-compliant reporting, and interactive dashboard development using the ADSL and ADAE datasets from the {pharmaverseadam} package. 

Throughout this assessment, I prioritized pharmaceutical industry best practices, including explicit namespacing, defensive programing, and comprehensive clinical-logic documentation.

🗂️ Repository Structure

This assessment is structured into three distinct folders corresponding to each of the three questions given:

Question_1/: TEAE Summary Table

Generates a regulatory-compliant Treatment-Emergent Adverse Event (TEAE) summary table. 

* question_1.R: Script utilizing {gtsummary} and {tidyverse} to filter for TEAEs (TRTEMFL == "Y") and aggregate subject counts/percentages by System Organ Class (SOC) and Preferred Term (PT).
* teae_summary.html: The exported HTML table output.

Question_2/: AE Severity Visualization

Develops a publication-quality visualization of adverse event (AE) distributions.

* question_2.R: Script utilizing {ggplot2} to construct a stacked bar chart. It aggregates unique subjects per System Organ Class (SOC) per Severity, preventing duplicate patient counts within its severity level for each SOC.
* ae_severity_plot.png: The exported publication-quality PNG plot.

Question_3/: Interactive R Shiny Application

Integrates the AE visualization from Question_2 into a dynamic interactive dashboard.

* question_3.R: Contains the UI and Server logic for a {shiny} application that allows users to filter the AE Severity Visualization dynamically by Treatment ARM (ACTARM).

⚙️ Setup & Execution

Prerequisites: Ensure you have R (version 4.2.0 or higher) installed. The following packages are required:

install.packages(c("pharmaverseadam", "tidyverse", "gtsummary", "ggplot2", "shiny", "gt"))

Running the code:

* Clone this repository to your local machine or Postit Cloud environment.
* Execute question_1.R and question_2.R sequentially to review the static data manipulation, table generation, and plotting logic. Outputs will be saved to their respective directories.
* Open question_3.R and click "Run App" (in RStudio) to launch the interactive Shiny dashboard.

💡 Methodology Used & Best Practices

To ensure the codebase is robust, reproducible, and ready for a clinical reporting environment, the following practices were implemented:

* Traceability: Script headers include medadata defining inputs, outputs, and purpose.
* Explicit Namespacing: Functions are called with their package prefixes to prevent masking conflicts and improve dependency tracking.
* Defensive Programming: Implementation of stopifnot() and shiny::req() to validate data presence before execution to prevent silent failures.
* Documentation: Code comments to explain the clinical or business logic behind the R operations. 
