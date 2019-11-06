library(purrr)
library(dplyr)
library(ggplot2)
library(readr)
library(ggthemes)
library(scales)
library(devtools)

devtools::load_all(path = here::here("packages", "saler"), reset = TRUE)

# desired_rev and deals are the user-specific API into this script; it will be refactored into a
# set of functions. In the meantime, change these and only these

#
# What is the target revenue
#
desired_rev <- 3500000

#
# 'deals' is a data.frame consisting of
#### the name
#### the revenue associated with the deal
#### the mean probability of the deal landing
#### the variance of the mean probability
####
#### "Deal 1 is worth $1,200,000 and we think we have a 50% +/- 10%
#### chance of landing it"
#
deals <- tribble(
   ~ name, ~ revenue_lo, ~rev_lo_prob, ~revenue_hi, ~rev_hi_prob, ~ booking_mean, ~ booking_var,
    "Deal 1", 1200000,1, 1200000, 0, .5, .1,
    "Deal 2", 1100000,0.5, 1200000,0.5,  0.5, 0,
    "Deal 3", 800000,0.75, 900000, 0.25, 1, 0,
    "Deal 4", 1400000, 1, 1400000, 0, 0.3, .1,
    "Deal 5", 1750000,0.75, 2000000, 0.25, .2, .1,
    "Deal 6", 400000, 0.01, 1500000, 0.99, 1, 0,
    "Deal 7", 100000, 0.5, 100000, 0.5, .7, .1
)

deals <- get_deals("https://docs.google.com/spreadsheets/d/e/2PACX-1vTuk1k1ObW1GQv9_AZZW_IwsQ0O1jtv_9HMSQINq9u6fOQE6BkjKSYneodmSLpMRfV8UhfbjnJB5TOR/pub?gid=278219439&single=true&output=csv")

N = 1000000

oob <- validate_deals(deals)

if (nrow(oob) > 0) {
   msg <- paste(oob$name)
   stop(msg)
} else {
   # convert from mean and variance to alpha and beta for the
   # beta function
   
   sure_things <- deals %>% filter(booking_mean == 1)
   
   not_sure_things <- deals %>%
      filter(booking_mean < 1)
   
   not_sure_things <- not_sure_things %>% 
      cbind(map2_df(not_sure_things$booking_mean, not_sure_things$booking_var, est_beta_params))
   
   # for each deal, simulate the revenue across N probabilities
   rev_not_sure <- not_sure_things %>% select(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob, alpha, beta) %>%
      pmap(est_booking_revenue, N)
   
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
    # the probability of exeeding the target revenue is the mean
   # of the sum of each simulation that exceeds the target
   prob_of_success <- mean(rev_df$rev > desired_rev)
   
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
      mutate(ymax = if_else(x > desired_rev, ymax, 0))
   
   # plot the bad boy
   p <- plot_it(rev_df, target_rev, prob_of_success)
   
   probs <- c(0,.25, 0.5, 0.75, 0.9, 1)
   
   prob_df <- quantile(rev_df$rev, probs = probs) %>% as.data.frame()
   
   prob_df$prob <- 1-probs
   
   colnames(prob_df) <- c("revenue", "probability")
   rownames(prob_df) <- NULL
   prob_df
}

p
