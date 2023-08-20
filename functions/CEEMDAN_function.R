#####################################################

# This file contains the function used in this investigation to apply the CEEMDAN 
# Decomposition method


# Function to do CEEMDAN
ceemdan_function <- function(series, scaled = FALSE) {
  
  # if scaled series are required, scale
  if (scaled == TRUE) {
    series <- (series - min(series))/(max(series) - min(series))
  }
  
  # first determine numer of IMFs to be computed:
  num_IMFs <- round(log2(length(unlist(series, use.names = FALSE))))
  
  # set parameters:
  ensemble <- 250
  siftings <- 750
  S <- 6 # the highest range in documentation
  noise = 0.2 # as suggested in documentation
  seed = 343
  
  # do CEEMDAN with preset parameters
  IMFs <- Rlibeemd::ceemdan(series, num_imfs = num_IMFs, 
                            ensemble_size = ensemble, 
                            num_siftings = siftings,
                            S_number = S,
                            noise_strength = noise,
                            rng_seed = seed)
  
  # convert to a data frame, and add the original series on to the end
  IMFs_df <- IMFs %>% as.data.frame() %>% mutate(series = series)
  
  return(IMFs_df)
}