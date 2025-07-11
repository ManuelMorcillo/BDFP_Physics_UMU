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
library(pdftools)
library(grid)
library(gridExtra)

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
combinations <- c("C0")
for (i in 1:ncomb){
  combinations[i] <- paste0("C",i-1)
}

# Define study period
years <- 1980:2020

plots <- list()
for (i in 1:length(combinations)){
  file <- paste0(dir_data,"FWI_1980_2020_SPAIN_1degree_",combinations[i],"_year.nc")
  nc <- nc_open(file)
  var_data <- ncvar_get(nc, "FWI")

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
  
  # For test significance
  FWI_trend <- FWI %>%
    group_by(longitude,latitude) %>%
    summarise(
      slope = sens.slope(FWI)$estimates*10, # Calculate slope / 10 years
      sign = mk.test(FWI)$p.value # Mann-Kendall test for trend significance
    )
  
  # Read country borders data and filter for Spain
  world_borders <- ne_countries(scale = "medium", returnclass = "sf")
  spain_borders <- world_borders[world_borders$name == "Spain",]
  
  # Determine plot limits based on FWI trend data, adding a 2-degree buffer
  min_longitude <- min(FWI_trend$longitude) - 2
  max_longitude <- max(FWI_trend$longitude) + 2
  min_latitude <- min(FWI_trend$latitude) - 2
  max_latitude <- max(FWI_trend$latitude) + 2
  
  # Limit the plot to the specified geographic bounds
  plot_limits <- st_bbox(c(xmin = min_longitude, xmax = max_longitude, ymin = min_latitude, ymax = max_latitude), crs = 4326)
  spain_borders_filtered <- st_intersection(spain_borders, st_as_sfc(plot_limits))
  
  # Create a map visualizing the FWI trend and significant trends across Spain
  if (combinations[i]=="C0") {
    plot_fwi_trend <- ggplot() +
      geom_tile(data = FWI_trend, aes(x = longitude, y = latitude, fill = slope)) + # Tile layer for slope
      scale_fill_gradientn(name="Slope\n[z-score/decade]",colors = rev(brewer.pal(11, "BrBG")),limits=c(-0.8,0.8),breaks=seq(-0.8,0.8,0.2)) + # Color scale
      geom_point(data = filter(FWI_trend, sign < 0.05), aes(x = longitude, y = latitude, color = "p-value <0.05"), 
                 size = 0.8, show.legend = TRUE) +
      scale_color_manual(values = c("p-value <0.05" = "black"), name = "", labels = c("p-value <0.05")) +
      labs(
        title = paste0("Trend of the annual mean\nFWI for ",combinations[i]," (1980-2020)"),
        caption = "Database: ERA5 (Vitolo et al, 2020)",
        x = "Longitude [º]",
        y = "Latitude [º]"
      )+
      theme_light()+
      theme(plot.margin = unit(c(0,0,0,0), "cm"),plot.title = element_text(size=12,face = "bold"),
            legend.text = element_text(size = 12),plot.caption = element_text(size = 11))+
      coord_sf(crs = 4326, xlim = c(min_longitude, max_longitude), ylim = c(min_latitude, max_latitude)) +
      geom_sf(data = spain_borders_filtered, color = "black", fill = NA) # Outline of Spain
  } 
  
  if (combinations[i]=="C1"|combinations[i]=="C2"|combinations[i]=="C3"|combinations[i]=="C4"){
    plot_fwi_trend <- ggplot() +
      geom_tile(data = FWI_trend, aes(x = longitude, y = latitude, fill = slope)) + # Tile layer for slope
      scale_fill_gradientn(name="Slope\n[z-score/decade]",colors = rev(brewer.pal(11, "BrBG")),limits=c(-0.8,0.8),breaks=seq(-0.8,0.8,0.2)) + # Color scale
      geom_point(data = filter(FWI_trend, sign < 0.05), aes(x = longitude, y = latitude, color = "p-value <0.05"), 
                 size = 0.8, show.legend = TRUE) +
      scale_color_manual(values = c("p-value <0.05" = "black"), name = "", labels = c("p-value <0.05")) +
      labs(
        title = paste0("Trend of the annual mean\nFWI for ",combinations[i]," (1980-2020)"),
        caption = "Database: ERA5",
        x = "Longitude [º]",
        y = "Latitude [º]"
      ) +
      theme_light()+
      theme(plot.margin = unit(c(0,0,0,0), "cm"),plot.title = element_text(size=12,face = "bold"),
            legend.text = element_text(size = 12),plot.caption = element_text(size = 11))+
      coord_sf(crs = 4326, xlim = c(min_longitude, max_longitude), ylim = c(min_latitude, max_latitude)) +
      geom_sf(data = spain_borders_filtered, color = "black", fill = NA) # Outline of Spain
  }
  
  # Now, save the plot to a PDF using ggsave
  ggsave(paste0(dir_out, "FWI_Trend_Annual_Mean_Map_", combinations[i], ".pdf"), plot_fwi_trend, width = 10, height = 8)

  plot_ <- paste0("plot_",combinations[i],collapse = "")
  plots[[plot_]]<- plot_fwi_trend
}

multiplot <- function(..., plotlist = NULL, cols = 1, layout = NULL, heights = NULL, widths = NULL) {
  if (!requireNamespace("gridExtra")) {
    stop("gridExtra package is required. Please install it.")
  }
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots <- length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots / cols)),
                     ncol = cols, nrow = ceiling(numPlots / cols)
    )
  }
  
  gridExtra::grid.arrange(grobs = plots, newpage = TRUE, layout_matrix = layout, heights = heights, widths = widths)
}

layout <- matrix(c(1,1,2,3,4,5), nrow = 3, byrow = TRUE)
print(layout)
pdf(paste0(dir_out,"FWI_Trend_Annual_Mean_Maps.pdf"),width = 10, height = 8)
multiplot(plots$plot_C0,
          plots$plot_C1, 
          plots$plot_C2,
          plots$plot_C3,
          plots$plot_C4,
          layout = layout )
dev.off()

