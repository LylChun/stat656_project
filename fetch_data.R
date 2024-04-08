### Script to fetch stock data
# Created: 4/8/24, last updated 4/8/24
# Author: Elizabeth Chun

### load libraries
library(tidyquant) # used to fetch stock data
library(dplyr) # used for data wrangling


### fetch data and create df
stock_names = read.csv('project/constituents_sp500_feb4_2024.csv')

start_date = as.Date("2023-01-01", format = "%Y-%m-%d")
end_date = as.Date("2023-12-31", format = "%Y-%m-%d")
stock_list = lapply(as.list(stock_names$Ticker), tq_get, from = start_date, to = end_date)

stock_df = bind_rows(stock_list)

### write df to csv
write.csv(stock_df, file = "project/stock_data.csv", row.names = FALSE)
