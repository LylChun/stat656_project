### Script to create stock models
# Created: 4/8/24, last updated 4/8/24
# Author: Elizabeth Chun

### load packages
library(dplyr)
library(keras)
library(ggplot2)

### source processed data
# includes important configs like length_segment, max_length_input, etc
source("project/process_data.R")

### build model framework

## 1. define data generator
# currently only works for default max_length_input, delay, length_segment, step
# batch size can be changed, shuffle untested
generator <- function(data, max_length_input = 7, delay = 1, length_segment = 1, shuffle = FALSE,
                      batch_size = 300, step = 1) {

  max_index = nrow(data)

  ### will  need to be adjusted for segment_length
  seqvec = Vectorize(seq.default, vectorize.args = c("from", "to"))
  breakpoints = c(0, which(data$ticker[2:nrow(data)] - data$ticker[1:(nrow(data) - 1)] != 0), max_index) + 1

  idx_bool = rep(TRUE, max_index)
  leading_zs = as.vector(seqvec(breakpoints[1:(length(breakpoints) - 1)],
                                breakpoints[1:(length(breakpoints) - 1)] + max_length_input - 1))
  idx_bool[leading_zs] = FALSE
  indices = which(idx_bool)

  i = 1

  matdata = matrix(data$close_scaled, nrow = max_index)

  function() {
    if (shuffle) {
      indices = sample(indices, replace = FALSE)
    }
    if (i + batch_size >= length(indices)) # not enough indices left for full batch
      i <<- 1
    rows = c(indices[i:min(i + batch_size - 1, length(indices))])
    i <<- i + length(rows)

    samples <- array(0, dim = c(length(rows),
                                max_length_input / step,
                                dim(matdata)[[-1]]))
    targets <- array(0, dim = c(length(rows)))
    for (j in 1:length(rows)) {
      indices <- seq(rows[[j]] - max_length_input, rows[[j]]-1,
                     length.out = dim(samples)[[2]])
      samples[j,,] <- matdata[indices,]
      targets[[j]] <- matdata[rows[[j]]]
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
traingenerator = generator(stock_train, max_length_input = 7, batch_size = 100)
valgenerator = generator(stock_val, max_length_input = 7, batch_size = 10)
testgenerator = generator(stock_test, max_length_input = 7, batch_size = 10)

## 3. design and compile very simple lstm mode
model <- keras_model_sequential() %>%
  layer_lstm(units = 32, input_shape = list(NULL, 1)) %>%
  layer_dense(units = 1)

model %>% compile(
  optimizer = optimizer_rmsprop(),
  loss = "mae"
)

## 4. fit model and evaluate
history <- model %>% fit(
  traingenerator,
  steps_per_epoch = 1200,
  epochs = 3,
  validation_data = valgenerator,
  validation_steps = 50
)

preds = predict(model, testgenerator, steps = 50)

## 5. create example plots showing first 10 stock predictions
pdf("project/plots/lstm_v1.pdf", onefile = TRUE, height = 7, width = 10)
for (i in 1:10) {
  single_stock = stock_test %>%
    filter(ticker == i) %>%
    mutate(
      index = 1:n(),
      prediction = c(rep(NA, max_length_input), preds[i])
    )
  stock_plot = ggplot(single_stock) +
    geom_line(aes(index, close_scaled), color = "black") +
    geom_point(aes(index, prediction), color = "red")
  print(stock_plot)
}
dev.off()
