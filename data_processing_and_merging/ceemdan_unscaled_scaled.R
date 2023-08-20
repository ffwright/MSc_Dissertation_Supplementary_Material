# a script to perform CEEMDAN on the t+h forecast time series
# A function that allows the implementation of scaling for ceemdan is also defined.

# Decomposition is done in parrellel due to large number of series to decompose
library(tidyverse)
library(parallel)
library(doParallel)
library(foreach)
library(Rlibeemd)

setwd("~/MSc_Thesis_Supplementary_Material/functions")
source('step_ahead_expectation_functions.R')
source('significance_test_functions.R')
source('CEEMDAN_function.R')

setwd("~/MSc_Thesis_Supplementary_Material")
merged_raw_data <- read_rds('merged_raw_data.rds')


# code to left allign all merged data sets
start <- Sys.time()
merged_left_alligned <- foreach(ticker = merged_raw_data) %do% {
  
  # find the number of merged sets for each ticker
  # merged_raw_data is made up of n sets, forecast_dates, and announcements
  # so we take the length and - 2 to get the number of sets
  num_sets = length(ticker) - 2
  
  left_alligned_data <- lapply(ticker[c(1:num_sets)], expectation_time_extract)
  
  list(left_alligned_data = left_alligned_data, 
       forecast_dates = ticker$forecast_dates, 
       announcements = ticker$announcement_dates)
}
merged_left_alligned <- set_names(merged_left_alligned, names(merged_raw_data)) 
Sys.time() -start 
 
# save the left_alligned data set
write_rds(merged_left_alligned, 'merged_left_alligned.rds')

merged_left_alligned <- read_rds('merged_left_alligned.rds')

# code to apply ceemdan to each of the left alligned sets in parelell#

### set up parrelel computing with clusters ###
no_cores <- detectCores(logical = TRUE)  

# assign clusters
cl <- makeCluster(no_cores-1)  
registerDoParallel(cl)  

# export necessary libraries to each cluster
parallel::clusterEvalQ(cl, expr = {
  library(tidyverse)
  library(parallel)
  library(doParallel)
  library(foreach)
  library(Rlibeemd)
  
})

parallel::clusterExport(cl,
                        list('ceemdan_function', 'min_max'),
                        env = environment())

# compute IMFs
start <- Sys.time()
# loop over each list of merged data sets
left_alligned_IMFs <- foreach(ticker = merged_left_alligned) %do% {
  
  left_alligned_data <- ticker$left_alligned_data
  # process each merged data set so that it is suitable for EMD decomposition
  # do this in parallel as each set as ~63 series to decompose
  IMF_data <- foreach(ticker_set = left_alligned_data) %dopar% {
    # trim the data frame with drop_na and transpose 
    IMFs <- ticker_set$expect_data %>% select(-future_day) %>% drop_na %>% t() %>%
      apply(MARGIN = 2, ceemdan_function)
    
    # named list to pass out of the parellelized loop
    list(IMFs = IMFs, generation_dates = ticker_set$generation_dates)
  }
  
  # output list that retains all input infromation
  list(IMF_data = IMF_data, forecast_dates = ticker$forecast_dates, 
       announcements = ticker$announcements)
}

# set names of each list of ticker data
left_alligned_IMFs <- set_names(left_alligned_IMFs, names(merged_left_alligned))
Sys.time() -start 

# compute scaled series IMFs using the option defined in 
# ceemdan_function above. This is the same as the above non-scaled implementation

start <- Sys.time()
scaled_left_alligned_IMFs <- foreach(ticker = merged_left_alligned) %do% {
  
  left_alligned_data <- ticker$left_alligned_data
  
  IMF_data <- foreach(ticker_set = left_alligned_data) %dopar% {
    IMFs <- ticker_set$expect_data %>% select(-future_day) %>% drop_na %>% t() %>%
      # passing the scaled = TRUE adds a min/max scaling step to the ceemdan process
      apply(MARGIN = 2, ceemdan_function, scaled = TRUE)
    
    list(IMFs = IMFs, generation_dates = ticker_set$generation_dates)
  }
  
  list(IMF_data = IMF_data, forecast_dates = ticker$forecast_dates, 
       announcements = ticker$announcements)
}

scaled_left_alligned_IMFs <- set_names(scaled_left_alligned_IMFs, names(merged_left_alligned))
Sys.time() -start 

# stop the cluster
stopCluster(cl)

# store the computed IMFs
write_rds(left_alligned_IMFs, 'left_alligned_IMFs.rds')
write_rds(scaled_left_alligned_IMFs, 'scaled_left_alligned_IMFs.rds')
