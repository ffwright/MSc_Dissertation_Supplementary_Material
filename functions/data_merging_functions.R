#################################################################
# This file contains functions for stitching Irithmics data sets#
# and extracting the "step ahead" forecasts from the diagonal of #
# the heatmap.                                                    #
##################################################################

require(tidyverse)

# a function to take a two elelment list of generation dates and a list of data
# data freames, establish the overlap, and merge the two sets.
#
# returns a two eleement list with the same names and order as as_of_dates
# so that merged data can be merged with other data using this function

stitich_function <- function(as_of_dates_list_1, as_of_dates_list_2) {
  
  # determine the degree of overlap between generation dates
  gen_dates1 <- as_of_dates_list_1$date
  gen_dates2 <- as_of_dates_list_2$date
  
  # returns index range of gen_dates1 that match gen2
  matching <- match(gen_dates2, gen_dates1) %>% na.omit() %>% range()
  
  # drop the overlapping data from the first list (as second has more forecast info)
  head_data1 <- as_of_dates_list_1$data[-(matching[1]:matching[2])]
  
  # append the lists and merge generation dates
  merged_list <- append(head_data1, as_of_dates_list_2$data)
  merged_dates <- unique(c( gen_dates1,  gen_dates2))
  
  # return a list with the same names as input data so other lists can be merged
  return(list(date = merged_dates, data = merged_list))
}

#################################################################################

# a function that determines overlap between data files and merges them using stitich_function
# it takes in a list of already extracted Irithmics data files
# it returns the merged list, and the "breakpoint" which is the index of the file that did not have
# a date overlap with the previous merged files

file_merge <- function(data_file_list, start = 1) {
  # iniitialise the first file as merged file
  merged_as_of <- data_file_list[[start]][[2]]

  # loop over each file an sequentially merge them if there is overlap
  # if there is no generation date overlap, break out of loop
  for(i in (start + 1):length(data_file_list)) {
    # check of generation dates overlap
    matching <- unlist(match(merged_as_of[[1]], data_file_list[[i]][[2]][[1]])) %>% na.omit()

  if (length(matching) == 0) {
    break       # breaks the loop if there are no longer any matches
  }
    # if we have matching dates, do the stitch function
    merged_as_of <- stitich_function(merged_as_of, data_file_list[[i]][[2]])
  }
  return(list(merged_data = merged_as_of, break_point = i))
}

############################################################################################

# a function to merge all eligable files for a given ticker
# INPUTS: a list of files for a given ticker
# OUTPUTS a list containing lists of the merged data 
ticker_merge <- function(ticker_files) {
  
  # determine number of files and initialize start point
  n_files <- length(ticker_files)
  start <- 1
  
  merged_list <- vector('list',)
  for (i in 1:n_files) {
    temp <- file_merge(ticker_files, start = start)
    
    # store resulting merged set as a list
    merged_list <- append(merged_list, list(temp[[1]]))
    
    # update start with the previous breakpoint
    start <- unlist(temp[[2]])
    
    # break out of loop if all files have been looped over
    if (start == n_files) {
      break
    }
  }
  return(merged_list)
}


