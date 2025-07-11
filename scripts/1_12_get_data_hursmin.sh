#!/bin/bash 
# pf sh instead of bash in mac

y1=1979
y2=2022
m1=1
m2=12
d1=1
d2=31

# Variables to be downloaded
vars=("tas" "td")
varlongnames=('2m_temperature' '2m_dewpoint_temperature')

for year in $(seq $y1 $y2); do
    for month in $(seq -w $m1 $m2); do
        for day in $(seq -w $d1 $d2); do

            # Download both tas and td
            for index in ${!vars[@]}; do
                var=${vars[$index]}
                varlongname=${varlongnames[$index]}

                cat > kk4sed <<EOF
s#SSSVARIABLE#${varlongname}#g
s#SSSYEAR#${year}#g
s#SSSMONTH#${month}#g
s#SSSDAY#${day}#g
EOF

               sed -f kk4sed 1_13_download-cds-era5-4sed.py > download_cds_era5_${var}.py
               rm kk4sed

               chmod u+x download_cds_era5_${var}.py
               python3 download_cds_era5_${var}.py

				cdo -f nc copy download.grib ${var}_${year}${month}${day}.nc
            done
   cdo chname,\2d,td td_${year}${month}${day}.nc ofile.nc
  mv ofile.nc td_${year}${month}${day}.nc
cdo chname,\2t,tas tas_${year}${month}${day}.nc ofile.nc
  mv ofile.nc tas_${year}${month}${day}.nc 
    # Calculate es  
	cdo expr,'es_tas=610.94*exp((17.625*tas)/(tas+243.04))' tas_${year}${month}${day}.nc es_tas_${year}${month}${day}.nc
	cdo expr,'es_td=610.94*exp((17.625*td)/(td+243.04))' td_${year}${month}${day}.nc es_td_${year}${month}${day}.nc

# Calculate RH using the two es values
cdo mulc,100 -div es_td_${year}${month}${day}.nc es_tas_${year}${month}${day}.nc hourly_rh_${year}${month}${day}.nc

# Calculate the daily min of RH
cdo -b F32 -daymin hourly_rh_${year}${month}${day}.nc daily_rh_${year}${month}${day}.nc

# Calculate daily mean of TAS
cdo -b F32 -daymean tas_${year}${month}${day}.nc tasmean_${year}${month}${day}.nc

# Regrid the daily mean RH to 1-degree resolution 
cdo -b F32 remapbil,~/Dropbox/model/fire_database/source/griddes.txt daily_rh_${year}${month}${day}.nc rhmin_${year}${month}${day}_1degree.nc

# Regrid the daily mean TAS to 1-degree resolution 
cdo -b F32 remapbil,~/Dropbox/model/fire_database/source/griddes.txt tasmean_${year}${month}${day}.nc tasmean_${year}${month}${day}_1degree.nc
mv tasmean_${year}${month}${day}_1degree.nc /diskonfire/ERA5/daily_values/tasmean/tasmean_${year}${month}${day}_1degree.nc

cdo chname,es_td,rhmin rhmin_${year}${month}${day}_1degree.nc ofile.nc
mv ofile.nc rhmin_${year}${month}${day}_1degree.nc
rm *tas* *td* *_rh*
 done
    
    done
done

