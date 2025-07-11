#################################################################################################
#		
# Title: Variables aproximadas para el cálculo del Índice Meteorológico de Incendios Forestales sobre España Peninsular y las Islas Baleares
#        Approximate variables for the calculation of the Forest Fire Weather Index over Peninsular Spain and the Balearic Islands
#
# 				
# Authors: 	... ... , University of Murcia ( ... ... )
#
#            Marco Turco, University of Murcia (marco.turco@um.es)
#        Manuel Morcillo, University of Murcia (manuel.morcillom@um.es / manuel.morcillom@gmail.com)  
#               
#
#################################################################################################

#################################################################################################
# A. General instructions 
#################################################################################################

This project is designed to be executed with shell scripts, Python and R codes. 
Execute script files in the order they are listed.

Data sources:

- ERA5 variables:
https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels

- Fire Weather Index:
https://cds.climate.copernicus.eu/cdsapp#!/dataset/cems-fire-historical-v1

- 1ºx1º grid: https://github.com/SantanderMetGroup/ATLAS/raw/main/reference-grids/land_sea_mask_1degree.nc4

Notes regarding reproducibility:

Script files starting with "1_" in their name are for data preprocessing. 
Most of these script files will NOT run because we do not include the 
raw data because files are simply too large to conveniently share. 
We suggest you run scripts starting with "2_" which directly reproduces the 
results in the paper. 

If you have any questions or wish to express any comment to the authors, please 
contact Manuel Morcillo and/or Dr. Marco Turco at the emails indicated above.


#################################################################################################
# B. Description of script files
#################################################################################################

Scripts for data preparation

- 1_1_get_data_fwi.sh 
Shell script to download selected Fire Weather Index data from copernicus  

- 1_2_download-cds-era5-4sed.py
Python script to download daily Fire Weather Index data from copernicus

- 1_3_extract_fwi_1979_2021_spain_1degree.sh
Shell script to extract FWI data for SPAIN from 1979 to 2021, and interpolated from 0.25º to 1º

- 1_4_get_data_pr.sh
Shell script to download hourly precipitation data from copernicus, aggregated daily, and interpolated from 0.25º to 1º

- 1_5_download-cds-era5-4sed.py
Python script to download hourly precipitation data from copernicus

- 1_6_get_data_sfcWind.sh
Shell script to download hourly U and V (wind component) data from copernicus, calculate wind speed, aggregated daily, and interpolated from 0.25º to 1º

- 1_7_download-cds-era5-4sed.py
Python script to download hourly U+V  data from copernicus

- 1_8_get_data_tasmax.sh
Shell script to download hourly temperature data from copernicus, aggregated daily, and interpolated from 0.25º to 1º
- 1_9_download-cds-era5-4sed.py
Python script to download hourly temperature data from copernicus

- 1_10_get_data_hurs.sh
Shell script to download hourly temperature and dew-point temperature data from copernicus, compute rh, aggregated daily (mean), and interpolated from 0.25º to 1º

- 1_11_download-cds-era5-4sed.py
Python script to download hourly temperature and dew-point temperature  data from copernicus

- 1_12_get_data_hursmin.sh
Shell script to download hourly temperature and dew-point temperature data from copernicus, compute rh, aggregated daily (min rh, mean tmax), and interpolated from 0.25º to 1º

- 1_13_download-cds-era5-4sed.py
Python script to download hourly temperature and dew-point temperature data from copernicus

- 1_14_extract_forcings_1979_2021_spain_1degree.sh
Shell script to extract forcings data (pr, wind, temp, rh) data for SPAIN from 1979 to 2021

- 1_15_calculate_FWI_daily_values.R
R script to compute FWI index from daily forcings data (pr, wind, temp, rh) data for SPAIN from 1979 to 2021

Scripts to reproduce the results in the paper.

- 2_1_calculate_trends_maps_year.R

- 2_2_calculate_trends_points_year.R

- 2_3_calculate_diff_trends_year.R

- 2_4_calculate_diff_trends_maps_year.R
