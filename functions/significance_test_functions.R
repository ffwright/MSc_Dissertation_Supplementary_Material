# script containing functions related to significance testing

# load required libraries:
library(tidyverse)

#### Min/Max scalar #############
# For the significicance test the input series bust be normalised before decomposition
# We use a min/max normalisation process to bound the series between [0,1]
min_max <- function(series) {
  min_max <- (series - min(series))/(max(series) - min(series))
  return(min_max)
}
#################################################################################

#### Mean Period Function ########
# This function counts the number of IMF peaks and compures the mean period
# by dividing the series length by the number of peaks.
mean_period_func <- function(IMF) {
  
  # get maxima (when second difference is negative)
  # N.B. the +1 accounts for the differencing dropping numbers
  peaks <- which(diff(sign(diff(IMF)))==-2)+1
  
  # get period by dividing length by number of peaks
  period <- length(unlist(IMF, use.names = FALSE))/length(peaks)
  return(period)
}
###############################################################################

#### Energy Density Function ############
# This function computes the energy density by takig the inner (dot) product of the series

energy_density_func <- function(IMF) {
  apply(IMF, MARGIN = 2, function(x) {sum(abs(x)^2)/length(x)})
}
###############################################################################

#### Confidence Interval Spread Line Function #######
# Function to compute the Wu test spread lines. These are the normal approximation 
# Spread lines that have a wider spread than the theoretical spread lines
# This could lead to an over rejection of statistical significance.
# One can specify a different alpha level to adjust the level of rejection for the test

confidence_intervals_func <- function(x, N, alpha = 0.01) {
  
  # get the quantile of the standard normal distribution
  k = qnorm(alpha)
  
  lower <- -x - k*sqrt(2/N)*exp(x/2) 
  
  upper <- -x + k*sqrt(2/N)*exp(x/2) 
  
  return(list(lower = lower, upper = upper))
}


