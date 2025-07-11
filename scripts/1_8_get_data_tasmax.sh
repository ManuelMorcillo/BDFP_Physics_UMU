#!/bin/sh

vars='tas'

y1=1981
y2=1981
m1=11
m2=11
d1=25
d2=25

dirout='/diskonfire/ERA5/daily_values/tasmax/'
cd $dirout

for variable in $vars; do

case $variable in
'tas') varlongname='2m_temperature'
esac

for year in $(seq $y1 $y2); do
  for month in $(seq -w $m1 $m2); do
    for day in $(seq -w $d1 $d2); do
      cat > kk4sed <<EOF
s#SSSVARIABLE#${varlongname}#g
s#SSSYEAR#${year}#g
s#SSSMONTH#${month}#g
s#SSSDAY#${day}#g
EOF

      sed -f kk4sed 1_9_download-cds-era5-4sed.py > download_cds_era5.py
      rm kk4sed

      chmod u+x download_cds_era5.py

      python3 download_cds_era5.py

      # Calculate daily maximum
      cdo -b F32 -ydaymax download.grib ofile.nc

      # Regrid the data
      cdo -b F32 -f nc remapbil,/home/marco/Dropbox/model/fire_database/source/griddes.txt ofile.nc tasmax_${year}${month}${day}_1degree.nc

      # Remove the downloaded GRIB file and the non-regridded tasmax file
      rm download.grib ofile.nc
    done
  done
done
done
