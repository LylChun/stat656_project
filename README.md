# Overview
This is a repo for our STAT 656 project in Spring 2024

Team Name: Machine Learners  
Team members: Elizabeth Chun, Minhyuk (Joseph) Kim, Sophia Lazcano

# How to work with this repository
There are 4 main files for running the analysis and reproducing outputs. You should only need to interact with two of them: config.R and models.R. The other files are used to fetch data (no editing unless desire new data pull) and process data (should be sourced/imported in models.R). 

1. **fetch_data.R** pulls stock price data using the tidyquant package and creates stock_data.csv. Should not need to be touched 
2. **config.R** sets important processing and modeling configs like lengths for input and output. Should be edited for params as needed. 
3. **process_data.R** loads the stock_data.csv and performs processing including data splitting, scaling, and encoding. Sources config for params. Should not need to be touched.  
4. **models.R** builds, trains, and evaluates models. Currently contains simple LSTM example. Sources process_data for data. Should be main work file.  

Old exploratory files have been moved to exploratory/*.

# Adding models
To add a new model, you can copy the models.R file and simply create your own keras model architecture and compile. In other words, model = keras_model_sequential() %>% [insert layers here]

# Data Notes
Data pulled from here: https://topforeignstocks.com/indices/components-of-the-sp-500-index/
csv file as of February 4th 2024

Modified to fix tickers for BRKB (corrected to BRK-B) and BFB (corrected to BF-B) and CDAYS (corrected to DAYS)

Caret does not seem to support multi-sample model fitting - i.e. it splits the entire timeseries in rolling windows assuming it is a single time series. Could fit separate models for each stock...not exactly our goal. Currently have chosen to use keras with data generators to fit multi-sample models

# Proposed workflow for project
1. Pick 3 models: suggested ARIMA (simple, linear type regression), XGBoost (tree based), transformer (deep learning)
  a. Maybe each of us responsible for one model?
2. Splitting: suggested to split OD/ID and check within sector vs between sector comparisons
3. Scaling: min-max, normalization, etc
4. Encoding: not sure if tickers and/or sectors need to be encoded as numeric
  a. not terribly interesting from a theoretical perspective
  b. but I think might be important from a practical perspective
  

# Proposed discussion points for task 2

Feynman method:  

1. How does data processing, in particular splitting, scaling, encoding, etc, affect prediction accuracy.
2. Define prediction accuracy, splitting, encoding, etc. 
3. Need to define test set (can discuss OD vs ID), cross-validation or some other method. Also define scaling (and why is it needed?), encoding (optional, not sure we need it). Lastly define prediction accuracy (mean square error? MAE? etc)
4. "Solidify concepts"
5. Iterate
