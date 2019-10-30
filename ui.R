library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Target Revenue Probability"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      numericInput("target_rev", "Target Revenue", value = 100000, min = 0),
      fileInput("deals_file", "Choose CSV File",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv")
      ),
      submitButton()
    ),
    
    # Show a plot of the generated distribution
    mainPanel(tabsetPanel(
      tabPanel("Info",
      plotOutput("probPlot"),
      hr(),
      div("The probabilities"),
      tableOutput("probsTable"),
      hr(),
      div("The Input Deals"),
      tableOutput("dealsTable")
      ),
      tabPanel("Help",
               div("An attempt to help estimate the probability of attaining a 
                   target revenue given a 'basket' of sales deals."),
               br(),
      div("Set the desired revenue target in the Target Revenue box, upload a basket
          of deals, and submit the changes. You will be presented with an overall 
          probability distribution, the probability of hitting the target, and revenue 
          points for specific probabilities (e.g. a 10% chance of hitting X, a 25% chance
          of hitting Y, etc)."),
      br(),
      div("The baseket of deals must be very well defined as a table of deals with a name,
          the revenue associated with the deal, an expected probability that the deal with 
          manifest, and a variance around that probability (e.g. 50% +/- 10%). Easiest to
          clone ",
      a(href = "https://docs.google.com/spreadsheets/d/1yS1861iwN3NYL_f-HfLEWAy32ZHbb_jRq1LRll4jVSg/edit?usp=sharing",
        "this Google Sheet"), ", edit it, and export it as a CSV. That CSV is what you want to upload."),
      br(),
      div("Very little error checking.")
    )
  )
)
))