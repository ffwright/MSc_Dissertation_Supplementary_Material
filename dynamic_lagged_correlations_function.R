# this file produces the time dpendant lagged cross correlation results
# for all g+1 and price and change series

library(tidyverse)
library(foreach)
library(forecast)
library(foreach)
library(ggpubr)
library(ggcorrplot)
library(gridExtra)

source('significance_test_functions.R')

# source prepared data objects
long_left_IMFs <- read_rds('long_series_IMFs.rds')
unscaled_price_IMFs <- read_rds('unscaled_price_IMFs.rds')

tickers <- names(long_left_IMFs)
IMF_names <- colnames(long_left_IMFs$ADM$IMF_data[[1]]$IMFs[[1]])[1:8]

# lagged cross-correlation function
lagged_ccf <- function(series_x, series_y) {
  
  # get the length of the series (this is the same)
  len <- length(series_x)
  
  # get estimates of the mean periods
  x_period <- mean_period_func(series_x) %>% round(0)
  y_period <- mean_period_func(series_y) %>% round(0)
  
  
  # set the window to be max period (or 6 if the period is less than 6) 
  # for vey large periods we limit the window size to 90 (or for the residual)
  window <- min(max(6, max(x_period, y_period)), 90)
  
  # set the max lag to be half the window size -1 (to avoid division by 0)
  lag <- (window/2)
  
  # initialize values for looping
  cc_list <- vector('list', len) %>%
    set_names(as.character(seq(1,len)))
  
  # start the at g = half the window length 
  # and set the end to the length minus half the window
  # this maximises the window over which correlations are computed
  for (i in (window/2):(len - window/2)) {
    ccf <- forecast::Ccf(series_x[(i-window/2 + 1):(i+window/2)],
                         series_y[(i-window/2 + 1):(i+window/2)],
                         lag.max = lag, plot = FALSE)
    
    cc_list[[i]] <- data.frame(lag = ccf$lag, coef = ccf$acf)
    
  }
  cc_df <- cc_list %>% bind_rows(.id = 'g')
  
  cc_df <- cc_df %>% mutate(g = as.numeric(g))
  return(cc_df)
}


# compute the lagged correlations for each ticker and forecast
lagged_g1_correlations <- foreach(ticker = tickers) %do% {
  ticker_score_IMFs <- long_left_IMFs[[ticker]]$IMF_data
  price_IMFs <- unscaled_price_IMFs[[ticker]]$price_IMFs
  change_IMFs <- unscaled_price_IMFs[[ticker]]$change_IMFs
  
  # loop over any multiple forecasts
  cor_list <- foreach(i = seq(1, length(ticker_score_IMFs))) %do% {
    # apply lagged ccf to each IMF series
    g1 <- ticker_score_IMFs[[i]]$IMFs[[1]][,1:8]
    price <- price_IMFs[[i]][,1:8]
    change <- change_IMFs[[i]][,1:8]
    
    lagged_correlations <- foreach(j = seq(1, 8)) %do% {
      lagged_cc_price <- lagged_ccf(g1[,j], price[,j])
      lagged_cc_change <- lagged_ccf(g1[,j], change[,j])
      
      corr_list <- list(price_cor = lagged_cc_price, change_cor = lagged_cc_change)
    }
  }
}
lagged_g1_correlations <- set_names(lagged_g1_correlations, tickers)

# save the lagged correlations
write_rds(lagged_g1_correlations, 'TDL_Correlations.rds')

