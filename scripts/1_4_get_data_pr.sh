#!/bin/bash

# Function to handle the sed processing and download
sed_process_and_download() {
    local y=$1
    local m=$2
    local d=$3
    local file_var_name=$4

    cat > kk4sed <<EOF
s#SSSVARIABLE#${varlongname}#g
s#SSSYEAR#${y}#g
s#SSSMONTH#${m}#g
s#SSSDAY#${d}#g
EOF
    sed -f kk4sed 1_5_download-cds-era5-4sed.py > download_cds_era5.py
    chmod u+x download_cds_era5.py
    python3 download_cds_era5.py
    local file_name="precip_${y}${m}${d}_download.grib"
    mv download.grib $file_name

    eval $file_var_name=$file_name
}

vars='tp'
y1=1940
y2=2022
m1=1
m2=12
d2=31

for variable in $vars; do
    case $variable in
    'tp') varlongname='total_precipitation' ;;
    esac

    next_file=""

    for year in $(seq $y1 $y2); do
        for month in $(seq -w $m1 $m2); do

            # For year 1940 and month 1, start from day 2, otherwise start from day 1
            if [ "$year" -eq 1940 ] && [ "$month" -eq 01 ]; then
                d1=2
            else
                d1=1
            fi    

		for day in $(seq -w $d1 $d2); do
                if [ -z "$next_file" ]; then
                    # If next_file is empty (first iteration), download current day
                    sed_process_and_download $year $month $day "curr_file"

                    # Download next day
		    next_day=$(date -d "$year-$month-$day + 1 day" "+%Y-%m-%d")
                    sed_process_and_download ${next_day:0:4} ${next_day:5:2} ${next_day:8:2} "next_file"
                else
                    # If next_file is not empty, it becomes the curr_file
                    curr_file=$next_file
                    next_file=""
                    # Download next day (as it has not been downloaded yet)
                     next_day=$(date -d "$year-$month-$day + 1 day" "+%Y-%m-%d")
                    sed_process_and_download ${next_day:0:4} ${next_day:5:2} ${next_day:8:2} "next_file"
                fi

                # Sum hours 1-23 from the current file
				cdo -b F32 timselsum,23,1 $curr_file tmp1.nc
                # Select hour 00 from the next file
				cdo -b F32 selhour,0 $next_file tmp2.nc
                # Add the two files
				cdo -b F32 add tmp1.nc tmp2.nc ofile.nc
                rm tmp1.nc tmp2.nc $curr_file

                # Regrid the data
                cdo -b F32 -f nc remapcon,~/Dropbox/model/fire_database/source/griddes.txt ofile.nc precip_${year}${month}${day}_1degree.nc
                rm ofile.nc
                
            done
        done
    done
done
