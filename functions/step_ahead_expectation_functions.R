# script to format merged data as t+f alligned data
library(tidyverse)
library(hrbrthemes)




expectation_time_extract <- function(file) {
  
  # determine the maximum length and force all vectors to be that length 
  # this allows for cbind
  max_length <- lapply(file$data, length) %>% unlist(use.names = FALSE) %>% max()
  file_data <- lapply(file$data, function (x) {length(x) <- max_length; x})
  
  # iniitialize temp data frame
  temp <- data.frame(na.omit(file_data[[1]]))
  
  # extract each forecast (list in file_data), remove NAs and bind together as columns
  # this produces a data frame where each row is the forecast for h days ahead
  # and each column is the whole forecast made on a generation day
  for (i in 2:length(file_data)) {
    temp <- gdata::cbindX(temp, data.frame(na.omit(file_data[[i]])))
  }
  temp <- set_names(temp, as.character(seq(1,ncol(temp))))
  # create a relative date variable to pivot around
  future_day <- rownames(temp)
  
  # extract generation dates
  return(list(expect_data = cbind(future_day, temp),
              generation_dates = file$date))
}



hm_plot_exp_space <- function(exp_time_data) {
  long_temp <- exp_time_data %>% 
    pivot_longer(-'future_day') %>% 
    mutate(future_day = as.numeric(future_day),
           generation_day = as.numeric(name)) 
  
  heat_map <- long_temp %>% ggplot() +
    geom_tile(aes(x = future_day, y = generation_day, fill = value)) +
    scale_fill_gradient2(high = 'blue', mid = 'white', low = 'red', na.value = 'lightgrey') +
    scale_y_reverse() +
    labs(x = 'Future Day, t+h',
         y = 'Generation Day',
         fill = 'Irithmics Score')
    theme_ipsum()
  return(heat_map)
}




add_announcements_diag <- function(heatmap, expect_data, announcement_dates, merged_forecasts) {
  # select matching announcement dates:
  match_announcements <- announcement_dates[match(as_date(merged_forecasts[[1]]), announcement_dates)] %>% na.omit()
  
  # get start points by atching indices of announncements and generation dates
  announcement_y_start <- match(announcement_dates, as_date(merged_forecasts[[1]])) %>% na.omit()
  
  # get length of forecast (width of the plot) which is the number of future days 
  # in the forecast period
  plot_width <- max(expect_data[[1]][,1]) %>% as.numeric()
  
  # get y-end points by taking plot width from start points
  announcement_y_end <- announcement_y_start - plot_width
  
  # store as data frame for plotting
  announcement_dates_lines <- data.frame(x = rep(0, length(announcement_y_start)),
                                         xend = rep(plot_width - 1, length(announcement_y_start)),
                                         y = announcement_y_start,
                                         yend = announcement_y_end,
                                         dates = as.factor(match_announcements))
  
  # set the end points of first announcement which exceed the bounds of the plot to 0
if(announcement_dates_lines$yend[1] < 0) {
    # trim the x length
    announcement_dates_lines$xend[1] <- announcement_dates_lines$xend[1] + announcement_dates_lines$yend[1]
      
    # set y_end to 0
    announcement_dates_lines$yend[1] <- 0
}


  # add lines to plot:
  
  # add dashed black line for announcement date
  # use geom_segement to plot as abline is bugged
  # N.B. the last generation date is made on the announcement date so the line must intersect at max(gen_date) - 1
  
  out_plot <- heatmap + 
    geom_segment(data = announcement_dates_lines,
                         aes(x=x, y=y, xend=xend, yend=yend),
                         color='black', linetype = 'dashed', linewidth = 0.6, alpha = 0.75) +
    geom_text(data = announcement_dates_lines, 
              aes(x = xend/2, y = (y + yend)/2, label = format.Date(dates, '%d %b %y'),
                  angle = (180/pi)*atan((y- yend)/xend)),
              size = 2,
              alpha = 0.5, 
              nudge_y = -1.5)
    
  
  return(out_plot)
}

# out_plot
# ticker_data <- merged_data$ULVR
# merged_forecasts <- ticker_data[[2]]
# expect_data <- expectation_time_extract(merged_forecasts)
# hm_plot <- hm_plot_exp_space(expect_data$expect_data)
# announcement_dates <- ticker_data$announcement_dates
# 
# add_announcements_diag(hm_plot, expect_data, announcement_dates, merged_forecasts)
