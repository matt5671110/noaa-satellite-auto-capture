#!/bin/bash

#Change directory to script directory
dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$dir"

#Make output directories if they don't exist
[ -d images ] || mkdir images
[ -d tles ] || mkdir tles
[ -d audio ] || mkdir audio

#Update TLEs
wget -q https://www.celestrak.com/NORAD/elements/weather.txt -O weather.txt
grep "NOAA 15" weather.txt -A 2 > noaa.tle
grep "NOAA 18" weather.txt -A 2 >> noaa.tle
grep "NOAA 19" weather.txt -A 2 >> noaa.tle
[ -e "weather.txt" ] && rm weather.txt

#Remove data from previously scheduled jobs
[ -e "queued_jobs" ] && rm queued_jobs

#Schedule Satellite Passes for the day
./schedule_satellite.sh "NOAA 19" 137.1
./schedule_satellite.sh "NOAA 18" 137.9125
./schedule_satellite.sh "NOAA 15" 137.62

#Handle conflicts
/usr/bin/python3 handle_conflicts.py
