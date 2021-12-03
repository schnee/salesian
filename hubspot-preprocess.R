library(tidyverse)

deals <- readxl::read_xlsx("~/Downloads/hubspot-crm-exports-all-deals-all-fields-for-week-2021-12-01.xlsx") %>%
  janitor::clean_names() %>%
  rename(revenue_hi = amount,
         booking_mean = deal_probability) %>%
  mutate(rev_lo_prob=0,
         revenue_lo=0,
         rev_hi_prob=1,
         booking_var=0)
         


deals <- deals %>%
  filter(deal_stage != "Closed Lost") %>%
  filter(revenue_hi >0)

deals %>% write_csv("~/Downloads/pipeline_processed.csv")
