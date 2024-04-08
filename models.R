### Script to create stock models
# Created: 4/8/24, last updated 4/8/24
# Author: Elizabeth Chun

### load packages
library(dplyr)
library(keras)
library(ggplot2)

### clean environment and source processed data
# NOTE: to change configs like length_input, modify config file and re-source process_data.R
rm(list = ls())
source("project/process_data.R")

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
  # lag at end because last length_output points do not have enough forward points to allow forecast
  trailing_zs = as.vector(seqvec(breakpoints[2:length(breakpoints)] - length_output + 1,
                                 breakpoints[2:length(breakpoints)] - 1))
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
  steps_per_epoch = 850,
  epochs = 5,
  validation_data = valgenerator,
  validation_steps = 50
)

preds = predict(model, testgenerator, steps = 50)

## 5. create example plots showing first 10 stock predictions
pdf(paste0("project/output/lstm_i", length_input, "_o", length_output, ".pdf"), onefile = TRUE, height = 7, width = 10)
for (i in 1:25) {
  single_stock = stock_test %>%
    filter(ticker == i) %>%
    mutate(
      index = 1:n(),
      prediction = c(rep(NA, length_input), preds[i, ])
    )
  stock_plot = ggplot(single_stock) +
    geom_line(aes(index, close_scaled), color = "black") +
    geom_line(aes(index, prediction), color = "red", na.rm = TRUE)
  print(stock_plot)
}
dev.off()
