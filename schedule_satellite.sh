#!/bin/bash

#Variables
readonly min_elevation=25            #Satellites that don't reach this elevation will be ignored
readonly record_above_elevation=5    #Set to 0 to record entire pass (NOTE: values above 0 will not be exact)

#Change directory to script directory
dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$dir"

readonly satellite_name=$1
readonly frequency=$2
readonly tle_filename=`pwd -P`/noaa.tle
readonly receive_data_command=`pwd -P`/receive_data.sh

PREDICTION_START=`predict -t noaa.tle -p "${satellite_name}" | awk -v elev="$record_above_elevation" '{if($5>=elev){print; exit}}'`
PREDICTION_END=`predict -t noaa.tle -p "${satellite_name}" | tac | awk -v elev="$record_above_elevation" '{if($5>=elev){print; exit}}'`
TRUE_PREDICTION_END=`predict -t noaa.tle -p "${satellite_name}" | tail -n1`
MAX_ELEV=`predict -t noaa.tle -p "${satellite_name}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`


end_timestamp=`echo ${PREDICTION_END} | cut -d " " -f 1`
true_end_timestamp=`echo ${TRUE_PREDICTION_END} | cut -d " " -f 1`

while [ "`date --date=\"@${true_end_timestamp}\" +%D`" == "`date +%D`" ]
do
	start_timestamp=`echo ${PREDICTION_START} | cut -d " " -f 1`
	capture_duration=`expr ${end_timestamp} - ${start_timestamp}`

	if [ $MAX_ELEV -ge $min_elevation  ]
	then
		date_string=`TZ=UTC date --date="@${start_timestamp}"`
		local_date_string=`date --date="@${start_timestamp}" "+%H:%M %D"`
		OUTDATE=`TZ=UTC date --date="@${start_timestamp}" +%Y%m%d_%H%M%S`
		filename_base="${OUTDATE}-${1//" "}"
		echo "Scheduling ${satellite_name} at ${date_string}"
		echo "Local Time:    ${local_date_string}"
		echo "Max Elevation: ${MAX_ELEV}"
		echo "Filename base: ${filename_base}"

		prev_queue=`atq`
		echo "/bin/bash ${receive_data_command} \"${satellite_name}\" \"${frequency}\" \"${filename_base}\" \"${tle_filename}\" \"${start_timestamp}\" \"${capture_duration}\"" | at -M ${local_date_string}
		new_queue=`atq`
		atid=`diff <(echo "${prev_queue}") <(echo "${new_queue}") | tail -n1 | cut -d " " -f 2 | cut -f 1`
		echo "${atid} ${satellite_name//" "} ${start_timestamp} ${end_timestamp} ${MAX_ELEV}" >> queued_jobs
		
		echo ""
	fi

	next_predict=`expr $true_end_timestamp + 60`
	PREDICTION_START=`predict -t noaa.tle -p "${satellite_name}" ${next_predict} | awk -v elev="$record_above_elevation" '{if($5>=elev){print; exit}}'`
	PREDICTION_END=`predict -t noaa.tle -p "${satellite_name}" ${next_predict} | tac | awk -v elev="$record_above_elevation" '{if($5>=elev){print; exit}}'`
	TRUE_PREDICTION_END=`predict -t noaa.tle -p "${satellite_name}" ${next_predict} | tail -n1`
	MAX_ELEV=`predict -t noaa.tle -p "${satellite_name}" ${next_predict} | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

	end_timestamp=`echo ${PREDICTION_END} | cut -d " " -f 1`
	true_end_timestamp=`echo ${TRUE_PREDICTION_END} | cut -d " " -f 1`
done
