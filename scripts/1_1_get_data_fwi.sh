#!/bin/sh

y1=1979
y2=2022

vars='fwi'
dirout='/diskonfire/ERA5/FWIv4_1/'
cd $dirout

for variable in $vars; do

    case $variable in
    'fwi') varlongname='fire_weather_index' ;;
    esac

    for year in $(seq $y1 $y2); do
        for month in $(seq 1 12); do
            if [ $month -lt 10 ]; then
                month=0$month
            fi

            # Adjusting for January 1940 starting from the 3rd day
            start_day=1
            if [ $year -eq 1940 ] && [ $month -eq 01 ]; then
                start_day=3
            fi

            for day in $(seq $start_day 31); do
                if [ $day -lt 10 ]; then
                    day=0$day
                fi

                cat > kk4sed << EOF
s#SSSYEAR#${year}#g
s#SSSMONTH#${month}#g
s#SSSDAY#${day}#g
EOF

                sed -f kk4sed 1_2_download-cds-era5-4sed.py > download-cds-era5.py
                rm kk4sed

                chmod u+x download-cds-era5.py

                python3 download-cds-era5.py

                output_filename=$dirout/$variable-era5-$year$month$day.nc
                mv download.nc $output_filename

            done
        done
    done
done
