#!/bin/bash

# Define base directory for the 'pr' data
# BASE_DIR="/diskonfire/ERA5/daily_values/pr"
# BASE_DIR="/diskonfire/ERA5/daily_values/sfcWind"
# BASE_DIR="/diskonfire/ERA5/daily_values/tasmax"
BASE_DIR="/diskonfire/ERA5/daily_values/tasmean"
# BASE_DIR="/diskonfire/ERA5/daily_values/hurs"
# BASE_DIR="/diskonfire/ERA5/daily_values/hursmin"

# Define geographical bounding box for Spain
BBOX="-10,5,36,44"

############## pr
# cdo cat $BASE_DIR/precip_*_1degree.nc ofile1.nc
# cdo selyear,1979/2021 ofile1.nc ofile2.nc
# cdo sellonlatbox,$BBOX ofile2.nc $BASE_DIR/pr_1979_2021_SPAIN_1degree.nc
# rm ofile*

############## sfcWind
# cdo cat $BASE_DIR/wind_speed_yearly_*.nc ofile1.nc
# cdo selyear,1979/2021 ofile1.nc ofile2.nc
# cdo sellonlatbox,$BBOX ofile2.nc $BASE_DIR/sfcWind_1979_2021_SPAIN_1degree.nc
# rm ofile*

############## tasmax
# mv $BASE_DIR/tasmax_1979-2022_spa.nc $BASE_DIR/tasmax_1979_2021_SPAIN_1degree.nc

############## tasmean
cdo cat $BASE_DIR/tasmean_yearly_*.nc ofile1.nc
cdo selyear,1979/2021 ofile1.nc ofile2.nc
cdo sellonlatbox,$BBOX ofile2.nc $BASE_DIR/tasmean_1979_2021_SPAIN_1degree.nc
rm ofile*

############## hurs
# cdo cat $BASE_DIR/rhmean_yearly_*.nc ofile1.nc
# cdo selyear,1979/2021 ofile1.nc ofile2.nc
# cdo sellonlatbox,$BBOX ofile2.nc $BASE_DIR/hurs_1979_2021_SPAIN_1degree.nc
# rm ofile*

############## hursmin
# cdo cat $BASE_DIR/rhmin_yearly_*.nc ofile1.nc
# cdo selyear,1979/2021 ofile1.nc ofile2.nc
# cdo sellonlatbox,$BBOX ofile2.nc $BASE_DIR/hursmin_1979_2021_SPAIN_1degree.nc
# rm ofile*