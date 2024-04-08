### Script to process stock data
# Created: 4/6/24, last updated 4/8/24
# Author: Elizabeth Chun

### load packages and data
library(dplyr)
stock_df = read.csv("project/stock_data.csv")

### create data splits
nstocks = 501 # some stocks don't have the full 250 (for example if it started after January)
length_total = 250 # total points for each stock should be 250
length_segment = 1 #  how many points to forecast (currently only 1 supported)
max_length_input = 7 # how many previous points to use in forecasting (change possible supported?)
stock_split = stock_df %>%
  group_by(symbol) %>%
  filter(n() == length_total) %>% # standardize for ease
  mutate(
    # create splits (note lagging stucture)
    train = c(rep(1, length_total - length_segment*2), rep(0, length_segment*2)),
    val = c(rep(0, length_total - length_segment*2 - max_length_input),
            rep(1, max_length_input + length_segment), rep(0, length_segment)),
    test = c(rep(0, length_total - length_segment - max_length_input),
             rep(1, length_segment + max_length_input))
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
