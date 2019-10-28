library(purrr)
library(dplyr)
library(ggplot2)
library(readr)
library(ggthemes)
library(scales)

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
   ~name, ~revenue, ~mean, ~var,
   "Deal 1", 1200000, .5, .1,
   "Deal 2", 900000, .2, .1,
   "Deal 3", 800000, .5, .1,
   "Deal 4", 1400000, .1, .05,
   "Deal 5", 2000000, .5, .1,
   "Deal 6", 500000, .7, .1,
   "Deal 7", 100000, .5, .1
)

estRevenue <- function(revenue, alpha, beta, N){
  rbernoulli(N, p=rbeta(N, alpha, beta)) * revenue}

estBetaParams <- function(mu, var) {
  alpha <- ((1 - mu) / var - 1 / mu) * mu ^ 2
  beta <- alpha * (1 / mu - 1)
  return(params = list(alpha = alpha, beta = beta))
}

N = 1000000


# convert from mean and variance to alpha and beta for the 
# beta function
deals <- deals %>% cbind(map2_df(deals$mean, deals$var, estBetaParams))

# for each deal, simulate the revenue across N probabilities
revenue <- pmap(deals %>% select(revenue, alpha, beta), estRevenue, N)

# the probability of exeeding the target revenue is the mean
# of the sum of each simulation that exceeds the target
prob_of_success <- mean(Reduce('+', revenue) > desired_rev)

# build some data frames for plotting
rev_df <- Reduce('+', revenue) %>% data.frame(rev = .) 

# the ribbon dataframe. Draws a ribbon under the density for the simulations that exceed
# the target revenue. "512" is the default number of estimator points in the density
# kernel
rib_df <- data.frame(rev_df %>% map_df(~density(.x, from=min(rev_df$rev), to = max(rev_df$rev))$y),
                     ymin = 0, 
                     x = seq(from=min(rev_df$rev), to = max(rev_df$rev), length=512)) %>%
   rename(ymax = rev) %>%
   mutate(ymax = if_else(x>desired_rev, ymax, 0))

# plot the bad boy
rev_df %>% 
   ggplot(aes(x=rev)) + geom_density() +
   geom_ribbon(data=rib_df, aes(x=x, ymin=ymin, ymax=ymax), alpha = 0.2) +
   scale_x_continuous(labels = dollar) +
   theme_few() +
   labs(
      title = "Probabilities of Revenue",
      subtitle = paste0("Target revenue: ", dollar_format()(desired_rev), "\nProbability of attaining: ", 
                        100*round(prob_of_success, digits=2),"%"),
      caption = "The shaded section represents possible probabilities of exceeding the desired revenue",
      x = "Revenue",
      y = "Probability Density"
   ) +
   theme(axis.text.x = element_text(angle=45, hjust=1)) 

