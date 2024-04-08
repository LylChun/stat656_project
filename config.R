### Script to define configurations for modeling
# Created: 4/8/24, last updated 4/8/24
# Author: Elizabeth Chun

# some stocks don't have the full 250 (for example if it started after January)
# nstocks is only the stocks having full 250 points
nstocks = 501
length_total = 250 # total points for each stock should be 250

length_testing = 3 #  length of testing segment
length_input = 7 # how many previous points to use in forecasting
length_output = 3 # number of points to forecast into future

# note if length_testing and length_output are not the same, the forecast plots need to be adjusted
