#!/bin/bash

#Change directory to script directory
dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$dir"

readonly satellite_name=$1
readonly frequency=$2
readonly filename_base=$3
readonly tle_file=$4
readonly start_time=$5
readonly capture_duration=$6

readonly delay=`date +%s - ${start_time}`

[ $delay -gt 0 ] && sleep ${delay}

timeout ${capture_duration} rtl_fm -f ${frequency}M -s 60k -g 48 -E deemp -F 9 - | sox -t raw -e signed-integer -b 16 -r 60k - -t wav "audio/${filename_base}.wav.inprogress" rate 11025

if [ -e "audio/${filename_base}.wav.inprogress" ]
then
	grep "${satellite_name}" ${tle_file} -A 2 > "tles/${filename_base}.tle"
	mv "audio/${filename_base}.wav.inprogress" "audio/${filename_base}.wav"
	readonly satellite_name_noaa_apt=`echo "${satellite_name// /_}" | tr "[:upper:]" "[:lower:]"`
	noaa-apt -R no -m yes -T "tles/${filename_base}.tle" -s "${satellite_name_noaa_apt}" -o "images/${filename_base}.png" "audio/${filename_base}.wav"
fi
