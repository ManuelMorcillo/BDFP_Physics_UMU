rm(list = ls())
graphics.off()
gc()

# https://github.com/SantanderMetGroup/fireDanger/wiki

# devtools::install_github("SantanderMetGroup/transformeR")
# devtools::install_github("SantanderMetGroup/fireDanger")
# devtools::install_github("SantanderMetGroup/visualizeR")
# devtools::install_github("SantanderMetGroup/loadeR.2nc")
# devtools::install_github("SantanderMetGroup/loadeR.java")
# devtools::install_github("SantanderMetGroup/climate4R.UDG")
# devtools::install_github("SantanderMetGroup/loadeR")

library(loadeR)
library(transformeR)
library(visualizeR)
library(loadeR.2nc)
library(fireDanger)
library(RColorBrewer)
library(fields)
library(sp)

combination <- "C1"
  
  # C1: tasmean, rhmean
  # C2: tasmax, rhmean
  # C3: tasmean, rhmin
  # C4: tasmax, rhmin
  
# PARAMETER SETTING FOR DATA LOADING, INDEX CALCULATION AND EXPORT---------------------------------------------------------------------------
dir_data <- "C:/Users/manol/Documents/MEGAsync/Universidad/4º/TFG/data/"
# dir_grid <- "/Users/marco/Dropbox/model/fire_database/source/"
dir_grid <- dir_data

## Defining the reference grid:
sftlf <-
  loadGridData(
    dataset = paste0(dir_grid, "land_sea_mask_1degree_SPAIN.nc4"),
    "sftlf",
    dictionary = FALSE
  )
refGrid <- getGrid(sftlf)

# PARAMETERS
date_index <- 1

# Load data
# hurs_1979_2020_SPAIN_1degree.nc
# hursmin_1979_2020_SPAIN_1degree.nc
# pr_1979_2020_SPAIN_1degree.nc
# sfcWind_1979_2020_SPAIN_1degree.nc
# tasmax_1979_2020_SPAIN_1degree.nc
# tasmean_1979_2020_SPAIN_1degree.nc

pr.y <- loadGridData(dataset = paste0(dir_data, "pr_1979_2020_SPAIN_1degree.nc"), var = "tp", dictionary = FALSE)
wss.y <- loadGridData(dataset = paste0(dir_data, "sfcWind_1979_2020_SPAIN_1degree.nc"), var = "10u", dictionary = FALSE)
lon = pr.y$xyCoords$x
lat = pr.y$xyCoords$y

# C1: tasmean, rhmean
# C2: tasmax, rhmean
# C3: tasmean, rhmin
# C4: tasmax, rhmin

if (combination=="C1") {
  hurs.y <-
    loadGridData(
      dataset = paste0(dir_data, "hurs_1979_2020_SPAIN_1degree.nc"),
      var = "rhmean",
      dictionary = FALSE
    )
  tas.y <-
    loadGridData(
      dataset = paste0(dir_data, "tasmean_1979_2020_SPAIN_1degree.nc"),
      var = "tas",
      dictionary = FALSE
    )
} else if (combination=="C2"){
  hurs.y <-
    loadGridData(
      dataset = paste0(dir_data, "hurs_1979_2020_SPAIN_1degree.nc"),
      var = "rhmean",
      dictionary = FALSE
    )
  tas.y <-
    loadGridData(
      dataset = paste0(dir_data, "tasmax_1979_2020_SPAIN_1degree.nc"),
      var = "2t",
      dictionary = FALSE
    )
} else if (combination=="C3"){
  hurs.y <-
    loadGridData(
      dataset = paste0(dir_data, "hursmin_1979_2020_SPAIN_1degree.nc"),
      var = "rhmin",
      dictionary = FALSE
    )
  tas.y <-
    loadGridData(
      dataset = paste0(dir_data, "tasmean_1979_2020_SPAIN_1degree.nc"),
      var = "tas",
      dictionary = FALSE
    )
} else if (combination=="C4"){
  hurs.y <-
    loadGridData(
      dataset = paste0(dir_data, "hursmin_1979_2020_SPAIN_1degree.nc"),
      var = "rhmin",
      dictionary = FALSE
    )
  tas.y <-
    loadGridData(
      dataset = paste0(dir_data, "tasmax_1979_2020_SPAIN_1degree.nc"),
      var = "2t",
      dictionary = FALSE
    )
}

# Convert pr from m to mm
pr.y$Data <- pr.y$Data * 1000
attr(pr.y$Variable, "units") <- "mm"

# Convert tasmax from kelvin to celsius
tas.y$Data <- tas.y$Data -273.15
attr(tas.y$Variable, "units") <- "celsius"

# Convert wind speed from m/s to km/h if necessary
wss.y$Data <- wss.y$Data * 3.6
attr(wss.y$Variable, "units") <- "km/h"

check <- t(apply(wss.y$Data,c(2,3),mean))  
image.plot(lon,lat,check)

# Convert the dates to Date objects, stripping the time part
pr.y$Dates$start <- as.Date(pr.y$Dates$start)
pr.y$Dates$end <- as.Date(pr.y$Dates$end)
tas.y$Dates$start <- as.Date(tas.y$Dates$start)
tas.y$Dates$end <- as.Date(tas.y$Dates$end)
hurs.y$Dates$start <- as.Date(hurs.y$Dates$start)
hurs.y$Dates$end <- as.Date(hurs.y$Dates$end)
wss.y$Dates$start <- as.Date(wss.y$Dates$start)
wss.y$Dates$end <- as.Date(wss.y$Dates$end)

tas.y$Variable$varName <- "tas"
pr.y$Variable$varName <- "tp"
hurs.y$Variable$varName <- "hurs"
wss.y$Variable$varName <- "wss"

# Calculate FWI
multigrid_fwi <- makeMultiGrid(tas = tas.y, hurs = hurs.y, pr = pr.y, wind = wss.y)
fwi.y <- fwiGrid(multigrid = multigrid_fwi, mask = sftlf)

fwi.y$Data <- fwi.y$Data[1,,,]  # This will index out the first dimension
dim(fwi.y$Data)

check <- t(apply(fwi.y$Data,c(2,3),mean))  
image.plot(lon,lat,check)

# Export FWI to NetCDF
ncFile <- paste0(dir_data, "FWI_1979_2020_SPAIN_1degree_",combination,".nc")
grid2nc(data = fwi.y, NetCDFOutFile = ncFile, missval = 1e20, prec = "float", globalAttributes = list())
