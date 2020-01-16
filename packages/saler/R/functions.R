suppressPackageStartupMessages({
  library(readr)
  library(purrr)
})

est_booking <- function(alpha, beta, N) {
  rbernoulli(N, p = rbeta(N, alpha, beta))
}

est_revenue <- function(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob, N) {
  sample(x = c(revenue_lo, revenue_hi), 
         size = N,  
         prob=c(rev_lo_prob, rev_hi_prob),
         replace=TRUE)
}

est_booking_revenue <- function(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob, alpha, beta, N) {
  est_booking(alpha, beta, N) * est_revenue(revenue_lo, rev_lo_prob, revenue_hi, rev_hi_prob, N)
  #(rbeta(N, alpha, beta) > 0.5) * revenue
}

est_beta_params <- function(mu, var) {
  alpha <- ((1 - mu) / var - 1 / mu) * mu ^ 2
  beta <- alpha * (1 / mu - 1)
  return(params = list(alpha = alpha, beta = beta))
}

validate_deals <- function(deals) {
  
  # find the deals with a booking probability outside of [0,1]
  d <- deals %>% filter(booking_mean < 1) %>%
    mutate(
      high = booking_mean + booking_var,
      low = booking_mean - booking_var,
      oob = if_else(high >= 1 | low <= 0, TRUE, FALSE)
    ) %>% select(-high, -low)
  
  # find the deals with a revenue probability (lo + hi) != 1
  d2 <- deals %>% mutate(
    oob = if_else(rev_lo_prob + rev_hi_prob != 1, TRUE, FALSE)
  )
  
  d %>% bind_rows(d2) %>% filter(oob == TRUE)
}

get_deals <- function(url) {
  readr::read_csv(url)
}

plot_it <- function(rev_df, rib_df, target_rev, prob_of_success) {
  rev_df %>%
    ggplot(aes(x = rev)) + geom_density() +
    geom_ribbon(data = rib_df,
                aes(x = x, ymin = ymin, ymax = ymax),
                alpha = 0.2, fill = "#A47AA9") +
    scale_x_continuous(labels = dollar) +
    theme_few() +
    labs(
      title = paste("Probability of Reaching Target: ",
                    100 * round(prob_of_success, digits = 2),
                    "%"),
      subtitle = paste0(
        "Target booking revenue: ",
        dollar_format()(target_rev)
      ),
      caption = "The shaded section represents possible probabilities of exceeding the desired revenue",
      x = "Revenue",
      y = "Probability Density"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

