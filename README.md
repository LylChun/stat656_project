# Overview
This is a repo for our STAT 656 project in Spring 2024

Team Name: Machine Learners

Team members: Elizabeth Chun, Minhyuk (Joseph) Kim, Sophia Lazcano

# Notes
Data pulled from here: https://topforeignstocks.com/indices/components-of-the-sp-500-index/
csv file as of February 4th 2024

Modified to fix tickers for BRKB (BRK-B) and BFB (BF-B)


# Proposed workflow for project
1. Pick 3 models: suggested ARIMA (simple, linear type regression), XGBoost (tree based), transformer (deep learning)
  a. Maybe each of us responsible for one model?
2. Splitting: suggested to split OD/ID and check within sector vs between sector comparisons
3. Scaling: min-max (not preferred imho), normalization, etc
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
