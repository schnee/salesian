library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Booking Target Revenue Probability"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      fileInput("deals_file", "Choose CSV File",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv")
      ),
      numericInput("target_rev", "Target Revenue", value = 1e6, min = 0),
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
                   target revenue given a 'basket' of sales deals", em("within a 
                                                                       given time period"),"."),
               br(),
      div("Set the desired revenue target in the Target Revenue box, upload a basket
          of deals, and submit the changes. You will be presented with an overall 
          probability distribution, the probability of hitting the target, and revenue 
          points for specific probabilities (e.g. a 10% chance of hitting X, a 25% chance
          of hitting Y, etc)."),
      br(),
      div("The basket of deals must be very well defined as a table of deals with a name,
          the low-side revenue associated with the deal, the low-side probability, 
          the high-side revenue, the high side probability, an expected probability that the deal with 
          manifest, and a variance around that probability (e.g. 50% +/- 10%). If you want to model deals that
          are 100% likely to close, enter a 1 for the mean and a 0 (zero) for the variance. Easiest to
          clone ",
      a(href = "https://docs.google.com/spreadsheets/d/1kNbJVZURMRdG6WAOzxrXuZ3-J6iYaF0q1e3Gi3U2qEk/edit?usp=sharing",
        "this Google Sheet"), ", edit it (ensuring that the column names are not edited), and export it as a CSV. 
        That CSV is what you want to upload."),
      br(),
      div("Very little error checking, but you will want to ensure that the low-side probability plus the 
          high-side probability equals 1, and that the booking probability +/- the booking variance is within
          (0,1) (e.g. greater than zero and less than one)."),
      br(),
      div("Github? ", a(href = "https://github.com/schnee/salesian", "Github"),".")
    )
  )
)
))