#!/bin/bash

# Define the path where the original daily NetCDF files are stored
DATA_DIR="/diskonfire/ERA5/FWIv4_1/"
cd $DATA_DIR

# Define start and end years
y1=1979
y2=2021

# Define start and end months
m1=1
m2=12

# Define start and end days
d1=1
d2=31

# Loop over each year
for year in $(seq $y1 $y2); do
    # Loop over each month
    for month in $(seq $m1 $m2); do
        # Loop over each day
        for day in $(seq $d1 $d2); do
            # Format month and day with leading zeros
            fmonth=$(printf "%02d" $month)
            fday=$(printf "%02d" $day)
            # Commands using formatted month and day
            cdo -b F32 -f nc remapbil,~/Dropbox/model/fire_database/source/griddes.txt fwi-era5-$year$fmonth$fday.nc fwi-era5-$year$fmonth$fday-1degree.nc
            cdo sellonlatbox,-10,5,36,44 fwi-era5-$year$fmonth$fday-1degree.nc fwi-era5-$year$fmonth$fday-1degree-SPAIN.nc
        done
    done
done
cdo cat fwi-era5-*-1degree-SPAIN.nc FWI_1979_2021_SPAIN_1degree.nc