### Script to create stock models
# Created: 4/8/24, last updated 4/8/24
# Author: Elizabeth Chun

### load packages
library(dplyr)
library(tidyr)
library(keras)
library(ggplot2)

### clean environment and source processed data
# NOTE: to change configs like length_input, modify config file and re-source process_data.R
rm(list = ls())
source("project/process_data.R")
cat("length_input =", length_input)

### build model framework
## 1. define data generator
generator <- function(data, length_input = 7, length_output = 1, shuffle = FALSE,
                      batch_size = 128) {

  max_index = nrow(data)

  ### will need to be adjusted for segment_length
  seqvec = Vectorize(seq.default, vectorize.args = c("from", "to"))
  breakpoints = c(0, which(data$ticker[2:nrow(data)] - data$ticker[1:(nrow(data) - 1)] != 0), max_index) + 1

  # indices should be the first point of the testing segment
  idx_bool = rep(TRUE, max_index)
  # lag in front because first length_input points do not have enough data behind to forecast
  leading_zs = as.vector(seqvec(breakpoints[1:(length(breakpoints) - 1)],
                                breakpoints[1:(length(breakpoints) - 1)] + length_input - 1))
  if (length_output == 1) {
    trailing_zs = NULL # all points acceptable since the idx represents the first output point
  } else {
    # lag at end because last length_output points do not have enough forward points to allow forecast
    trailing_zs = as.vector(seqvec(breakpoints[2:length(breakpoints)] - length_output + 1,
                                   breakpoints[2:length(breakpoints)] - 1))
  }
  idx_bool[c(leading_zs, trailing_zs)] = FALSE
  idx_loc = which(idx_bool)

  i = 1

  matdata = matrix(data$close_scaled, nrow = max_index)

  function() {
    if (shuffle) {
      idx_loc = sample(idx_loc, replace = FALSE)
    }
    if (i + batch_size >= length(idx_loc)) # not enough indices left for full batch
      i <<- 1
    rows = c(idx_loc[i:min(i + batch_size - 1, length(idx_loc))])
    i <<- i + length(rows)

    samples <- array(0, dim = c(length(rows),
                                length_input,
                                dim(matdata)[[-1]]))
    targets <- array(0, dim = c(length(rows),
                                length_output))
    for (j in 1:length(rows)) {
      indices <- seq(rows[[j]] - length_input, rows[[j]]-1,
                     length.out = dim(samples)[[2]])
      idx_targets = seq(rows[[j]], rows[[j]] + length_output - 1)
      samples[j,,] <- matdata[indices,]
      targets[j,] <- matdata[idx_targets,]
    }
    list(samples, targets)
  }
}

## 2. create data generators
# IMPORTANT NOTE:
# you must be very careful with the data generators - once created they advance every time
# they are called which means the "first" sample returned will depend on the
# internal state of the generator at that time. Safest (currently) is to only use them
# in one place after creation or re-create as needed.
traingenerator = generator(stock_train, length_input = length_input, length_output = length_output,
                           batch_size = 128, shuffle = TRUE)
valgenerator = generator(stock_val, length_input = length_input, length_output = length_output,
                         batch_size = 10, shuffle = FALSE)
testgenerator = generator(stock_test, length_input = length_input, length_output = length_output,
                          batch_size = 10, shuffle = FALSE)

## 3. design and compile very simple lstm mode
model <- keras_model_sequential() %>%
  layer_lstm(units = 32, input_shape = list(NULL, 1), return_sequences = TRUE) %>%
  layer_lstm(units = 32, input_shape = list(NULL, 1)) %>%
  layer_dense(length_output)

model %>% compile(
  optimizer = optimizer_rmsprop(),
  loss = "mae"
)

## 4. fit model and evaluate
history <- model %>% fit(
  traingenerator,
  steps_per_epoch = 500,
  epochs = 3,
  validation_data = valgenerator,
  validation_steps = 50
)

# evalgenerator = generator(stock_test, length_input = length_input, length_output = length_output,
#                           batch_size = 10, shuffle = FALSE)
# evaluate(model, evalgenerator, steps = 50)

## get predictions and back transform (assumes length_testing = length_output)
preds = predict(model, testgenerator, steps = 50)
back_transform = stock_test %>%
  group_by(symbol) %>%
  summarise(
    symbol = unique(symbol), minclose = unique(minclose), maxclose = unique(maxclose),
    ticker = unique(ticker), .groups = "drop"
  ) %>%
  arrange(ticker) %>%
  slice(1:500)
xform_preds = cbind(back_transform, preds) %>%
  mutate(
    across(all_of(c("1", "2", "3", "4", "5")), # EEE
           list(scaled = ~ .*(maxclose - minclose) + minclose))
  ) %>%
  select(symbol, ticker, one = `1_scaled`, two = `2_scaled`, three = `3_scaled`,
         four = `4_scaled`, five = `5_scaled`) # EEE

# xform_preds_long = xform_preds %>%
#   pivot_longer(cols = c("one", "two", "three"),
#                names_to = "index", values_to = "close_pred")
#
# pred_loss = stock_test %>%
#   group_by(symbol) %>%
#   mutate(
#     symbol = symbol,
#     close = c(rep(NA, length_input), close[(n() - length_output + 1):n()])
#   ) %>%
#   filter(ticker <= 500 & !is.na(close)) %>%
#   mutate(
#     index = c("one", "two", "three")
#   ) %>%
#   select(symbol, ticker, close, index) %>%
#   left_join(xform_preds_long, by = c("symbol", "ticker", "index")) %>%
#   mutate(
#     abs_diff = abs(close_pred - close)
#   ) %>%
#   group_by(symbol) %>%
#   summarise(
#     MAE = mean(abs_diff)
#   )

# tuning = data.frame(
#   length_input = length_input,
#   MAE = mean(pred_loss$MAE)
# )

# write.table(tuning, "project/retransformed_test_error.csv",
#             col.names = !file.exists("project/retransformed_test_error.csv"),
#             row.names = FALSE, append = TRUE, sep= ",")


## 5. write out predictions for 20 stocks
shiny_stock = c("AAPL", "MSFT", "AMZN", "GOOGL", "META",
                "BRK-B", "TSLA", "JPM", "XOM", "COST",
                "PFE", "LOW", "DIS", "VZ", "PYPL",
                "MAR", "F", "NEE", "LUV", "CMG")

for (i in 1:20) {
  preds = unlist(xform_preds[xform_preds$symbol == shiny_stock[i], 3:7]) # EEE

  single_stock = stock_test %>%
    filter(symbol == shiny_stock[i]) %>%
    mutate(
      prediction = c(rep(NA, length_input), preds),
      n_pred = length_output
    ) %>%
    select(symbol, date, close, prediction, n_pred)
  write.table(single_stock, "project/shiny_prediction_data.csv", row.names = FALSE,
              col.names = !file.exists("project/shiny_prediction_data.csv"),
              sep = ",", append = TRUE)
}


# ## 6. create example plots showing first 10 stock predictions
# pdf(paste0("project/output/lstm_i", length_input, "_o", length_output, ".pdf"), onefile = TRUE, height = 7, width = 10)
# for (i in 1:25) {
#   single_stock = stock_test %>%
#     filter(ticker == i) %>%
#     mutate(
#       index = 1:n(),
#       prediction = c(rep(NA, length_input), unlist(xform_preds[i, 3:5]))
#     )
#   stock_plot = ggplot(single_stock) +
#     geom_line(aes(index, close), color = "black") +
#     geom_line(aes(index, prediction), color = "red", na.rm = TRUE) +
#     ggtitle(single_stock$symbol[1])
#   print(stock_plot)
# }
# dev.off()


## create prediction and outcome
shiny_prediction_data <- read_csv("project/shiny_prediction_data.csv")

outcomes = shiny_prediction_data %>%
  group_by(symbol, n_pred) %>%
  mutate(
    today = close[50],
    # n_future = prediction[n()],
    n_actual = close[n()],
    # if stock goes up on average hold, else sell
    decision = ifelse(mean(prediction, na.rm = TRUE) > today, "hold", "sell"),
    # positive delta means you made money
    delta = ifelse(decision == "hold", n_actual - today, today - n_actual)
  )

outcomes_summary = outcomes %>%
  select(symbol, n_pred, decision, delta) %>%
  unique()


pdf("project/output/decisions.pdf", onefile = TRUE, width = 10, height = 7)
for (i in 1:20) {
  mydata = outcomes %>%
    filter(symbol == shiny_stock[i]) %>%
    filter(n_pred == 5)

  myplot = ggplot(mydata) +
    ggtitle(paste0(mydata$symbol[1],  " Model decision is ", mydata$decision[1],
                   " and you make/lose ", round(mydata$delta[1], 2), " dollars")) +
    geom_line(aes(date, close), color = "black") +
    geom_line(aes(date, prediction), color = "red")
  print(myplot)
}
dev.off()
