### Script to process stock data
# Created: 4/6/24, last updated 4/8/24
# Author: Elizabeth Chun

### load packages, data, and configs
library(dplyr)
stock_df = read.csv("project/stock_data.csv")
source("project/config.R")


### create data splits
stock_split = stock_df %>%
  group_by(symbol) %>%
  filter(n() == length_total) %>% # standardize for ease
  mutate(
    # create splits (note lagging structure)
    train = c(rep(1, length_total - length_testing*2), rep(0, length_testing*2)),
    val = c(rep(0, length_total - length_testing*2 - length_input),
            rep(1, length_input + length_testing), rep(0, length_testing)),
    test = c(rep(0, length_total - length_testing - length_input),
             rep(1, length_testing + length_input))
  ) %>%
  ungroup()

### scale data using training min/max; also encode symbol into numeric ticker
stock_scale = stock_split %>%
  group_by(symbol) %>%
  mutate(
    minclose = min(close[as.logical(train)]),
    maxclose = max(close[as.logical(train)]),
    close_scaled = (close - minclose)/(maxclose - minclose),
  ) %>%
  ungroup() %>%
  mutate(
    ticker = rep(1:nstocks, each = length_total)
  )

### create train/val/test dataframes
stock_train = stock_scale %>% filter(train == 1)
stock_val = stock_scale %>% filter(val == 1)
stock_test = stock_scale %>% filter(test == 1)

rm(list = c("stock_df", "stock_split", "stock_scale"))
