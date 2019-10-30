suppressPackageStartupMessages({
  library(readr)
  library(purrr)
})


est_revenue <- function(revenue, alpha, beta, N) {
  rbernoulli(N, p = rbeta(N, alpha, beta)) * revenue
  #(rbeta(N, alpha, beta) > 0.5) * revenue
}

est_beta_params <- function(mu, var) {
  alpha <- ((1 - mu) / var - 1 / mu) * mu ^ 2
  beta <- alpha * (1 / mu - 1)
  return(params = list(alpha = alpha, beta = beta))
}

validate_deals <- function(deals) {
  d <- deals %>%
    mutate(
      high = mean + var,
      low = mean - var,
      oob = if_else(high >= 1 | low <= 0, TRUE, FALSE)
    )
  
  d %>% filter(oob == TRUE)
}

get_deals <- function(url) {
  readr::read_csv(url)
}

