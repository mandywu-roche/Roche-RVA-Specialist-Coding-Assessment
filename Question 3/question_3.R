# ---------------------------------------------------
# Script Name: question_3.R
# Purpose: Interactive Shiny dashboard that displays the AE Severity
#          visualization from Question 2, with dynamic filtering by
#          Treatment Arm (ACTARM).
# Author: Mandy Wu
# Date: March 10, 2026
# Input Data: pharmaverseadam::adae
# Output Data: Interactive Shiny application
# R Version: 4.5.2
# ---------------------------------------------------

## ---- load required libraries ----
# Setup: Uncomment and run the line below if you are missing any dependencies
# install.packages(c("pharmaverseadam", "tidyverse", "gtsummary", "ggplot2", "shiny"))
library(pharmaverseadam)
library(tidyverse)
library(ggplot2)
library(shiny)

## ---- input data ----
adae <- pharmaverseadam::adae

# Ensure expected variables exist before proceeding
stopifnot(
  all(c("USUBJID", "ACTARM", "AESOC", "AESEV") %in% names(adae))
)

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

# Get all unique treatment arms for the filter dropdown
treatment_arms <- sort(unique(adae$ACTARM))

## ---- define UI ----
ui <- fluidPage(
  
  # Application title
  titlePanel("Adverse Event Severity by System Organ Class"),
  
  sidebarLayout(
    
    # Sidebar: Treatment Arm filter
    sidebarPanel(
      width = 3,
      
      # Treatment Arm filter
      # Using checkboxGroupInput to allow multi-select filtering
      # All arms are selected by default to match Q2 output on load
      checkboxGroupInput(
        inputId  = "selected_arms",
        label    = "Select Treatment Arm(s):",
        choices  = treatment_arms,
        selected = treatment_arms
      ),
      
      # Informational text for the user
      helpText(
        "Select one or more treatment arms to filter the chart.",
        "The chart displays the number of unique subjects per",
        "System Organ Class, stacked by AE Severity."
      )
    ),
    
    # Main panel: Plot display
    mainPanel(
      width = 9,
      plotOutput(
        outputId = "ae_severity_plot",
        height   = "700px"
      )
    )
  )
)

## ---- define server logic ----
server <- function(input, output, session) {
  
  # --- reactive data: filter and process based on selected treatment arms ----
  # Clinical Logic: Replicates the Q2 data pipeline with an additional
  # filter step for treatment arm. The deduplication, counting, and
  # factor ordering logic is identical to Question 2.
  ae_plot_data <- reactive({
    
    # Validate that at least one treatment arm is selected
    validate(
      need(
        length(input$selected_arms) > 0,
        "Please select at least one Treatment Arm to display the chart."
      )
    )
    
    # Step 1: Filter to selected treatment arms
    adae_filtered <- adae %>%
      filter(ACTARM %in% input$selected_arms)
    
    # Step 2: Deduplicate at subject level per SOC and severity
    # Clinical Logic: Each subject counted at most ONCE per severity
    # level within each SOC (same logic as Question 2)
    adae_dedup <- adae_filtered %>%
      distinct(USUBJID, AESOC, AESEV)
    
    # Step 3: Compute subject counts per SOC and severity
    ae_counts <- adae_dedup %>%
      count(AESOC, AESEV, name = "n_subjects")
    
    # Step 4: Order SOCs by increasing total frequency
    ae_counts <- ae_counts %>%
      mutate(AESOC = fct_reorder(AESOC, n_subjects, .fun = sum))
    
    # Step 5: Apply severity factor ordering
    ae_counts <- ae_counts %>%
      mutate(AESEV = factor(AESEV, levels = severity_levels))
    
    ae_counts
  })
  
  # --- reactive plot: build the stacked bar chart ----------------------------
  # Replicates the exact same ggplot structure from Question 2,
  # with a dynamic subtitle reflecting the selected treatment arm(s)
  output$ae_severity_plot <- renderPlot({
    
    # Build dynamic subtitle showing selected arm(s)
    selected_label <- paste(input$selected_arms, collapse = ", ")
    
    ggplot(
      data = ae_plot_data(),
      aes(x = n_subjects, y = AESOC, fill = AESEV)
    ) +
      geom_bar(
        stat  = "identity",
        width = 0.7
      ) +
      scale_fill_manual(
        values = severity_colors,
        name   = "AE Severity"
      ) +
      labs(
        title    = "Adverse Event Distribution by System Organ Class and Severity",
        subtitle = paste("Treatment Arm(s):", selected_label),
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
  })
}

## ---- launch application ----
shinyApp(ui = ui, server = server)