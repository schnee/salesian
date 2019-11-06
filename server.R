library(shiny)
library(purrr)
library(dplyr)
library(ggplot2)
library(readr)
library(ggthemes)
library(scales)
library(devtools)

devtools::load_all(path = here::here("packages", "saler"), reset = TRUE)

# Define server logic
server <- function(input, output, session) {
  

  file_data <- reactive({
    
    req(input$deals_file)
    
    inFile <- input$deals_file
    
    if (is.null(inFile))
      return(NULL)
    
    #put it in the session
    session$userData$deals <- read.csv(inFile$datapath)
    
    
    session$userData$deals
  })
  
  
  revenue_df_fn <- reactive( {
    N = 1000000
    
    deals<- file_data()
    
    sure_things <- deals %>% filter(booking_mean == 1)
    
    not_sure_things <- deals %>%
      filter(booking_mean < 1)
    
    not_sure_things <- not_sure_things %>% 
      cbind(map2_df(not_sure_things$booking_mean, not_sure_things$booking_var, est_beta_params))
    
    # for each not sure deal, simulate the revenue across N probabilities and simulate the booking probability
    # the all-in revenue is P(booking) * revenue
    rev_not_sure <- not_sure_things %>% select(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob, alpha, beta) %>%
      pmap(est_booking_revenue, N)
    
    # for each sure deal, the booking probability is 1.0. So we just need to estimate the revenue
    rev_sure <- sure_things %>% select(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob) %>%
      pmap(est_revenue, N)
    
    # build some data frames for plotting. rev_sure and rev_not_sure are lists of Nx1 vectors, one vector
    # for each sure or not sure deal. We need to item-wise sum each of these vectors into Nx2 vectors, and
    # then item-wise sum those into a single estimate for revenue
    rev_not_sure <- Reduce('+', rev_not_sure)
    rev_sure <- Reduce('+', rev_sure)
    
    the_rev <- NULL
    if (!is_null(rev_not_sure) & !is_null(rev_sure)) {
      the_rev <- rev_not_sure + rev_sure
    }
    
    if(!is_null(rev_not_sure) & is_null(rev_sure)){
      the_rev <- rev_not_sure
    }
    
    if(!is_null(rev_sure) & is_null(rev_not_sure)){
      the_rev <- rev_sure
    }
    
    
    rev_df <- data.frame(rev = the_rev)
    rev_df
    
  })
  
  output$dealsTable <- renderTable({
    file_data()
  })
  
  output$probsTable <- renderTable({
    
    rev_df <- revenue_df_fn()
    

    
    probs <- c(0,.25, 0.5, 0.75, 0.9, 1)
    
    prob_df <- quantile(rev_df$rev, probs = probs) %>% as.data.frame()
    
    prob_df$prob <- 1-probs
    
    colnames(prob_df) <- c("revenue", "probability")
    prob_df %>% select(probability, revenue)

  })
  
  output$probPlot <- renderPlot({

      rev_df <- revenue_df_fn()
      
      # the probability of exeeding the target revenue is the mean
      # of the sum of each simulation that exceeds the target
      prob_of_success <- mean(rev_df$rev > input$target_rev)
      
      
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
      plot_it(rev_df, input$target_rev, prob_of_success)

  })

}