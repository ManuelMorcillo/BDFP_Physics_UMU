# Clear the workspace and graphics, prepare for analysis
rm(list = ls()) # Remove all objects from the current workspace
graphics.off() # Close all open graphics devices
gc() # Perform garbage collection to free up memory

# Load required libraries
library(tidyverse) # For data manipulation and visualization
library(lubridate) # For date-time manipulation
library(trend) # For trend analysis
library(pals) # For color palettes
library(rnaturalearth) # For country borders
library(sf)
library(RColorBrewer)
library(ncdf4)
library(data.table)

# Set directories based on the system being used
where <- 'manu'
if (where=='mac'){
  dir_data <- '/Users/marco/Dropbox/estcena/scripts/TFG_MANU/data/'
  dir_out <- '/Users/marco/Dropbox/estcena/scripts/TFG_MANU/figures/'
} else if (where == 'manu') {
  dir_data <- "C:/Users/manol/Documents/MEGAsync/Universidad/4º/TFG/data/"
  dir_out <- "C:/Users/manol/Documents/MEGAsync/Universidad/4º/TFG/figures/"
}

# Set the combination identifier
ncomb <- 5
combinations <- c()
for (i in 1:ncomb){
  combinations[i] <- paste0("C",i-1)
}

# Define study period
years <- 1980:2020

file <- paste0(dir_data,"FWI_1980_2020_SPAIN_1degree_C0_year.nc")
nc <- nc_open(file)
var_data <- ncvar_get(nc,"FWI")
lat_var <- ncvar_get(nc, "latitude")
lon_var <- ncvar_get(nc, "longitude")

# Obtain dimensions
dim1_size <- dim(var_data)[1]
dim2_size <- dim(var_data)[2]
dim3_size <- dim(var_data)[3]

# Create vectors for each dimension
dim1 <- seq_len(dim1_size)
dim2 <- seq_len(dim2_size)
dim3 <- seq_len(dim3_size)

# Expand all possible combinations of dimensions
df <- expand.grid(time = years, latitude = lat_var, longitude = lon_var, KEEP.OUT.ATTRS = FALSE)

# Reorganize var_data so that the order is [time, latitude, longitude]
var_data_reorder <- aperm(var_data, c(3, 2, 1)) # aperm rearranges dimensions

# Flatten the data to match the rows in df
df$var_value <- as.vector(var_data_reorder)

# Convert to data.table
FWI <- as.data.table(df)

# Close the NetCDF file
nc_close(nc)

# Filter NA values and convert to tibble
FWI <- FWI %>% filter(!is.na(var_value)) %>% as_tibble()

# Rename variable for clarity
FWI <- FWI %>% rename(FWI = var_value)

# Scale the FWI column
FWI_std <- FWI %>% group_by(latitude,longitude)%>%
  mutate(
    mean_FWI = mean(FWI, na.rm = TRUE),
    std_dev_FWI = sd(FWI, na.rm = TRUE),
    standardized_FWI = (FWI - mean_FWI) / std_dev_FWI)

FWI$FWI <- FWI_std$standardized_FWI

# Convert latitude and longitude to an sf object for spatial operations
pts_df <- expand.grid(lon = unique(FWI$longitude), lat = unique(FWI$latitude))
pts_sf <- st_as_sf(pts_df, coords = c("lon", "lat"), crs = 4326)

# Convert FWI data to a spatial object using the coordinates (longitude, latitude)
FWI_sf <- st_as_sf(FWI, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

# Read country borders data and filter for Spain
world_borders <- ne_countries(scale = "medium", returnclass = "sf")
spain_borders <- world_borders[world_borders$name == "Spain",]

# Spatial join between FWI data and Spain polygon - keeps only data within Spain
FWI_filtered_sf <- st_intersection(FWI_sf, spain_borders)

# Convert back to a regular tibble/data.frame for further analysis
FWI_filtered <- as_tibble(FWI_filtered_sf)

# Calculate the weighted annual mean FWI
FWI_filtered <- FWI_filtered %>%
  mutate(weight = cos(latitude * pi / 180)) # Calculate weight

# This involves using the weight in the calculation of the mean
FWI_filtered <- group_by(FWI_filtered,time)
FWI_filtered <- summarise(FWI_filtered,
                          weighted_mean_FWI = sum(FWI * weight, na.rm = TRUE) 
                          / sum(weight, na.rm = TRUE))

# Note: Standardizing a variable involves subtracting its mean and dividing 
# by its standard deviation, so that the resulting variable has a mean 
# of 0 and a standard deviation of 1. This is useful for comparing variables 
# that are on different scales or for preparing data for certain modeling 
# algorithms that require variables to be on a common scale.

# We have to do this for maps
FWI_filtered$weighted_mean_anomaly=FWI_filtered$weighted_mean_FWI
FWIC0_filtered <- FWI_filtered

for (i in 2:length(combinations)){
  
  file <- paste0(dir_data,"FWI_1980_2020_SPAIN_1degree_",combinations[i],"_year.nc")
  nc <- nc_open(file)
  var_data <- ncvar_get(nc,"FWI")
  
  if (combinations[i]=="C1"|combinations[i]=="C2"|combinations[i]=="C3"|combinations[i]=="C4") {
    lat_var <- ncvar_get(nc,"lat") # Adjust to the actual latitude variable name
    lon_var <- ncvar_get(nc,"lon") # Adjust to the actual longitude variable name
  } else if (combinations[i]=="C0"){
    lat_var <- ncvar_get(nc,"latitude")
    lon_var <- ncvar_get(nc,"longitude")
  }
  
  # Obtain dimensions
  dim1_size <- dim(var_data)[1]
  dim2_size <- dim(var_data)[2]
  dim3_size <- dim(var_data)[3]
  
  # Create vectors for each dimension
  dim1 <- seq_len(dim1_size)
  dim2 <- seq_len(dim2_size)
  dim3 <- seq_len(dim3_size)
  
  # Expand all possible combinations of dimensions
  df <- expand.grid(time = years, latitude = lat_var, longitude = lon_var, KEEP.OUT.ATTRS = FALSE)
  
  # Reorganize var_data so that the order is [time, latitude, longitude]
  var_data_reorder <- aperm(var_data, c(3, 2, 1)) # aperm rearranges dimensions
  
  # Flatten the data to match the rows in df
  df$var_value <- as.vector(var_data_reorder)
  
  # Convert to data.table
  FWI <- as.data.table(df)
  
  # Close the NetCDF file
  nc_close(nc)
  
  # Filter NA values and convert to tibble
  FWI <- FWI %>% filter(!is.na(var_value)) %>% as_tibble()
  
  # Rename variable for clarity
  FWI <- FWI %>% rename(FWI = var_value)
  
  # Scale the FWI column
  FWI_std <- FWI %>% group_by(latitude,longitude)%>%
    mutate(
      mean_FWI = mean(FWI, na.rm = TRUE),
      std_dev_FWI = sd(FWI, na.rm = TRUE),
      standardized_FWI = (FWI - mean_FWI) / std_dev_FWI) %>% ungroup()
  
  FWI$FWI <- FWI_std$standardized_FWI
  
  #FWI$FWI <- as.vector(scale(FWI$FWI)) 
  
  # Convert latitude and longitude to an sf object for spatial operations
  pts_df <- expand.grid(lon = unique(FWI$longitude), lat = unique(FWI$latitude))
  pts_sf <- st_as_sf(pts_df, coords = c("lon", "lat"), crs = 4326)
  
  # Convert FWI data to a spatial object using the coordinates (longitude, latitude)
  FWI_sf <- st_as_sf(FWI, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
  
  # Read country borders data and filter for Spain
  world_borders <- ne_countries(scale = "medium", returnclass = "sf")
  spain_borders <- world_borders[world_borders$name == "Spain",]
  
  # Spatial join between FWI data and Spain polygon - keeps only data within Spain
  FWI_filtered_sf <- st_intersection(FWI_sf, spain_borders)
  
  # Convert back to a regular tibble/data.frame for further analysis
  FWI_filtered <- as_tibble(FWI_filtered_sf)
  
  # Calculate the weighted annual mean FWI
  FWI_filtered <- FWI_filtered %>%
    mutate(weight = cos(latitude * pi / 180)) # Calculate weight
  
  # This involves using the weight in the calculation of the mean
  FWI_filtered <- group_by(FWI_filtered,time)
  FWI_filtered <- summarise(FWI_filtered,
                              weighted_mean_FWI = sum(FWI * weight, na.rm = TRUE) 
                              / sum(weight, na.rm = TRUE))
  
  # Note: Standardizing a variable involves subtracting its mean and dividing 
  # by its standard deviation, so that the resulting variable has a mean 
  # of 0 and a standard deviation of 1. This is useful for comparing variables 
  # that are on different scales or for preparing data for certain modeling 
  # algorithms that require variables to be on a common scale.
  
  # We have to do this for maps
  FWI_filtered$weighted_mean_anomaly=FWI_filtered$weighted_mean_FWI
  
  # Lets make copies
  if (combinations[i]=="C1"){
    FWIC1_filtered <- FWI_filtered
    FWIC1_filtered$weighted_mean_anomaly <- FWI_filtered$weighted_mean_anomaly - FWIC0_filtered$weighted_mean_anomaly
  } else if (combinations[i]=="C2"){
    FWIC2_filtered <- FWI_filtered
    FWIC2_filtered$weighted_mean_anomaly <- FWI_filtered$weighted_mean_anomaly - FWIC0_filtered$weighted_mean_anomaly
  } else if (combinations[i]=="C3"){
    FWIC3_filtered <- FWI_filtered
    FWIC3_filtered$weighted_mean_anomaly <- FWI_filtered$weighted_mean_anomaly - FWIC0_filtered$weighted_mean_anomaly
  } else if (combinations[i]=="C4"){
    FWIC4_filtered <- FWI_filtered
    FWIC4_filtered$weighted_mean_anomaly <- FWI_filtered$weighted_mean_anomaly - FWIC0_filtered$weighted_mean_anomaly
  }
  
  # Lets get the slope and intercept for all combinations
  
   if (combinations[i]=="C1"){
    auxC1 = sens.slope(FWIC1_filtered$weighted_mean_anomaly)
    slopeC1 <- auxC1$estimates
    interceptC1 <- mean(FWIC1_filtered$weighted_mean_anomaly)-slopeC1*mean(FWIC1_filtered$time)
    
  } else if (combinations[i]=="C2"){
    auxC2 = sens.slope(FWIC2_filtered$weighted_mean_anomaly)
    slopeC2 <- auxC2$estimates
    interceptC2 <- mean(FWIC2_filtered$weighted_mean_anomaly)-slopeC2*mean(FWIC2_filtered$time)
    
  } else if (combinations[i]=="C3"){
    auxC3 = sens.slope(FWIC3_filtered$weighted_mean_anomaly)
    slopeC3 <- auxC3$estimates
    interceptC3 <- mean(FWIC3_filtered$weighted_mean_anomaly)-slopeC3*mean(FWIC3_filtered$time)
    
  } else if (combinations[i]=="C4"){
    auxC4 = sens.slope(FWIC4_filtered$weighted_mean_anomaly)
    slopeC4 <- auxC4$estimates
    interceptC4 <- mean(FWIC4_filtered$weighted_mean_anomaly)-slopeC4*mean(FWIC4_filtered$time)
  }

}
  
##########################################################################
## Trend analysis and visualization for C0 and C2 (standardized), plotting
## the annual mean FWI trend over years
##########################################################################

FWIC1_means <- rename(FWIC1_filtered,weighted_mean=weighted_mean_anomaly)
FWIC2_means <- rename(FWIC2_filtered,weighted_mean=weighted_mean_anomaly)
FWIC3_means <- rename(FWIC3_filtered,weighted_mean=weighted_mean_anomaly)
FWIC4_means <- rename(FWIC4_filtered,weighted_mean=weighted_mean_anomaly)

FWI_means <- bind_rows("C1-C0"=FWIC1_means,
                       "C2-C0"=FWIC2_means,
                       "C3-C0"=FWIC3_means,
                       "C4-C0"=FWIC4_means,.id="tibble")

# Create a PDF plot to visualize both trends
sig <- 2 # round
dec <- 2 # must show this digits
FWI_mean_line <- ggplot(FWI_means,aes(x = time
                                      ,y = weighted_mean
                                      ,color=tibble))+
  geom_point(shape=1)+
  geom_line()+
  scale_color_manual(values = c("C1-C0" = "purple2",
                                "C2-C0" = "cyan3",
                                "C3-C0" = "chartreuse2",
                                "C4-C0" = "orange")) +
  theme_light()+
  geom_abline(intercept = interceptC1,slope = slopeC1,color="purple2")+
  geom_abline(intercept = interceptC2,slope = slopeC2,color="cyan3")+
  geom_abline(intercept = interceptC3,slope = slopeC3,color="chartreuse2")+
  geom_abline(intercept = interceptC4,slope = slopeC4,color="orange")+
  annotate("text",x = 1993, y = 0.5+0.33,label = paste0("Trend C1-C0: " ,format(round(slopeC1*10,sig),nsmall = dec)," (C.I.: ",format(round(auxC1$conf.int[1]*10,sig),nsmall = dec),"/",format(round(auxC1$conf.int[2]*10,sig),nsmall = dec),") [z-score/decade]"))+
  annotate("text",x = 1993, y = 0.45+0.33-0.004,label = paste0("Trend C2-C0: ",format(round(slopeC2*10,sig),nsmall = dec)," (C.I.: ",format(round(auxC2$conf.int[1]*10,sig),nsmall = dec),"/",format(round(auxC2$conf.int[2]*10,sig),nsmall = dec),") [z-score/decade]"))+
  annotate("text",x = 1993, y = 0.4+0.33-0.008,label = paste0("Trend C3-C0: " ,format(round(slopeC3*10,sig),nsmall = dec)," (C.I.: ",format(round(auxC3$conf.int[1]*10,sig),nsmall = dec),"/",format(round(auxC3$conf.int[2]*10,sig),nsmall = dec),") [z-score/decade]"))+
  annotate("text",x = 1993, y = 0.35+0.33-0.012,label = paste0("Trend C4-C0: " ,format(round(slopeC4*10,sig),nsmall = dec)," (C.I.: ",format(round(auxC4$conf.int[1]*10,sig),nsmall = dec),"/",format(round(auxC4$conf.int[2]*10,sig),nsmall = dec),") [z-score/decade]"))+ 
  guides(color = guide_legend(title.position = "top",title.hjust = 0.5,label.position = "left"))+
  labs(x = "Time [years]", y = "FWI [z-score]",color ="",plot.caption = element_text(size = 12))

ggsave(paste0(dir_out, "FWI_Trend_Annual_Mean_diff_Line_",
              combinations[2],
              "+",combinations[3],
              "+",combinations[4],
              "+",combinations[5],".pdf"),FWI_mean_line, width = 8, height = 6)

