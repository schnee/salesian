library(shiny)
library(purrr)
library(dplyr)
library(ggplot2)
library(readr)
library(ggthemes)
library(scales)
library(devtools)

devtools::load_all(path = here::here("packages", "saler"), reset = TRUE)

# deals <- tribble(
#   ~ name, ~ revenue, ~ mean, ~ var,
#   "Deal 1", 1200000, .5, .1,
#   "Deal 2", 900000, .2, .1,
#   "Deal 3", 800000, .5, .1,
#   "Deal 4", 1400000, .1, .05,
#   "Deal 5", 2000000, .5, .1,
#   "Deal 6", 500000, .9, .01,
#   "Deal 7", 100000, .7, .1
# )

# Define server logic required to draw a histogram
server <- function(input, output) {
  

  file_data <- reactive({
    
    req(input$deals_file)
    
    inFile <- input$deals_file
    
    if (is.null(inFile))
      return(NULL)
    
    read.csv(inFile$datapath)
    
  })
  
  output$dealsTable <- renderTable({
    file_data()
  })
  
  output$probPlot <- renderPlot({
    

    
    N = 1000000
    
    deals<- file_data()

      # convert from mean and variance to alpha and beta for the
      # beta function
      deals <-
        deals %>% cbind(map2_df(deals$mean, deals$var, est_beta_params))
      
      # for each deal, simulate the revenue across N probabilities
      revenue <-
        pmap(deals %>% select(revenue, alpha, beta), est_revenue, N)
      
      # the probability of exeeding the target revenue is the mean
      # of the sum of each simulation that exceeds the target
      prob_of_success <- mean(Reduce('+', revenue) > input$target_rev)
      
      # build some data frames for plotting
      rev_df <- Reduce('+', revenue) %>% data.frame(rev = .)
      
      # the ribbon dataframe. Draws a ribbon under the density for the simulations that exceed
      # the target revenue. "512" is the default number of estimator points in the density
      # kernel
      rib_df <-
        data.frame(
          rev_df %>% map_df( ~ density(
            .x,
            from = min(rev_df$rev),
            to = max(rev_df$rev)
          )$y),
          ymin = 0,
          x = seq(
            from = min(rev_df$rev),
            to = max(rev_df$rev),
            length = 512
          )
        ) %>%
        rename(ymax = rev) %>%
        mutate(ymax = if_else(x > input$target_rev, ymax, 0))
      
      # plot the bad boy
      rev_df %>%
        ggplot(aes(x = rev)) + geom_density() +
        geom_ribbon(data = rib_df,
                    aes(x = x, ymin = ymin, ymax = ymax),
                    alpha = 0.2, fill = "#A47AA9") +
        scale_x_continuous(labels = dollar) +
        theme_few() +
        labs(
          title = "Probabilities of Revenue",
          subtitle = paste0(
            "Target revenue: ",
            dollar_format()(input$target_rev),
            "\nProbability of hitting target: ",
            100 * round(prob_of_success, digits = 2),
            "%"
          ),
          caption = "The shaded section represents possible probabilities of exceeding the desired revenue",
          x = "Revenue",
          y = "Probability Density"
        ) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
  })

}