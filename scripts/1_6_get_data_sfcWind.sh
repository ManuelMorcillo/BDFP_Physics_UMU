#!/bin/bash

y1=1940
y2=2022
m1=1
m2=12
d1=1
d2=31

sed_process_and_download() {
    variable=$1
    year=$2
    month=$3
    day=$4
    outfile=$5

    cat > kk4sed <<EOF
s#SSSVARIABLE#$variable#g
s#SSSYEAR#$year#g
s#SSSMONTH#$month#g
s#SSSDAY#$day#g
EOF

    sed -f kk4sed 1_7_download-cds-era5-4sed.py > download_cds_era5.py
    chmod u+x download_cds_era5.py
    python3 download_cds_era5.py
    mv download.grib $outfile
    rm kk4sed
}

for year in $(seq $y1 $y2); do
    for month in $(seq -w $m1 $m2); do
        for day in $(seq -w $d1 $d2); do
            # Download u10 and v10 for the day
            u10_file="wind_u10_${year}${month}${day}_download.grib"
            v10_file="wind_v10_${year}${month}${day}_download.grib"

            sed_process_and_download "10m_u_component_of_wind" $year $month $day $u10_file
            sed_process_and_download "10m_v_component_of_wind" $year $month $day $v10_file

            # Compute wind speed from u10 and v10 for the day
            sfcWind_daily_file_temp="wind_speed_daily_temp_${year}${month}${day}.nc"
            sfcWind_daily_file="wind_speed_daily_${year}${month}${day}_1degree.nc"

            if [[ -f "$u10_file" && -f "$v10_file" ]]; then
                # Compute the daily average wind speed
                cdo sqrt -add -sqr -timmean $u10_file -sqr -timmean $v10_file $sfcWind_daily_file_temp

                # Regrid the data
                cdo -b F32 -f nc remapbil,~/Dropbox/model/fire_database/source/griddes.txt $sfcWind_daily_file_temp $sfcWind_daily_file
                
                # Cleanup
                rm $u10_file $v10_file $sfcWind_daily_file_temp
            fi
        done
    done
done
