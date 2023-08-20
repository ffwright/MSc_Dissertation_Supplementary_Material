# a script to merge all overlapping files in the data set
library(jsonlite)
library(foreach)

setwd("~/MSc_Thesis_Supplementary_Material/data_processing")
source('data_merging_functions.R')


# get the list of big files
big_files <- data.frame(file_names = read_rds('big_file_list.rds'))

# get a list of unique tickers
tickers <- lapply(big_files[,1], function(file) str_split_1(file, pattern = ' ')[4]) %>%
                  unique() %>% unlist(use.names = FALSE)

# get lists of files for each ticker
# N.B. exact string matching to avoid issues like 'BA.XLON' capturing 'HSBA.XLON'incorrectly
files_by_ticker <- lapply(tickers, function(ticker) {
  file_names <- big_files[grepl(paste0('\\b',ticker,'\\b'), big_files$file_names),]
})

# set names to be tickers (and drop the XLON)
files_by_ticker <- set_names(files_by_ticker, lapply(tickers, function(x){str_split_1(x, '.XLON')[1]}))  # set names to be ticker

# extract the announcemnt dates for each file and store it with each ticker
files_by_ticker <- lapply(files_by_ticker, function(file_list) {
  list(file_names = file_list, 
       announcement = lubridate::ymd(file_list))
} )

# for each list of files read in the JSON and merge
setwd("~/MSc_Thesis_Supplementary_Material/data_folder")

merged_files <- vector('list', 91)
for (i in 1:length(files_by_ticker)) {
  
  # get file names and extract the JSON file
  file_list <- files_by_ticker[[i]][[1]]
  files <- lapply(file_list, jsonlite::fromJSON)
  
  # run the ticker_merge UDF on the list of ticker files
  merged_ticker_files <- ticker_merge(files)
  
  # store announcement dates for each ticker in the list object
  merged_ticker_files$announcement_dates <- files_by_ticker[[i]][[2]]
  
  # store forecast date range by extracting forecast ranges, merging, and keeping unique days
  merged_ticker_files$forecast_dates <- lapply(files, function(x) x[[1]]) %>% 
    unlist(use.names = FALSE) %>% unique() %>% as_date()
  
  # store to the output list
  merged_files[[i]] <- merged_ticker_files
}

# set names of groups of lists to be the corresponding ticker
merged_files <- set_names(merged_files, lapply(tickers, function(x){str_split_1(x, '.XLON')[1]}))  # set names to be ticker

setwd("~/MSc_Thesis_Supplementary_Material")
  
# save the merged file data:
write_rds(merged_files, 'merged_raw_data.rds')


