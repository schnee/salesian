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
    mainPanel(
      plotOutput("probPlot"),
      hr(),
      div("The probabilities"),
      tableOutput("probsTable"),
      hr(),
      div("The Input Deals"),
      tableOutput("dealsTable")
    )
  )
)