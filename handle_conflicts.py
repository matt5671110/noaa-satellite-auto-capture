#!/usr/bin/env python3

import os

if os.path.exists("queued_jobs"):
	data = []
	to_remove = []
	print("Checking for conflicts ...")
	with open("queued_jobs", "r") as file:
		for line in file:
			info = line.split(" ")
			job_data = {
				'atid': info[0],
				'satellite_name': info[1],
				'start_time': info[2],
				'end_time': info[3],
				'max_elev': info[4]
			}
			data.append(job_data)
	for job in data:
		current_atid = job['atid']
		if current_atid in to_remove:
			continue
		current_start_time = job['start_time']
		for other_job in data:
			if other_job['atid'] != current_atid:
				if current_start_time >= other_job['start_time'] and current_start_time <= other_job['end_time'] and other_job['atid'] not in to_remove:
					print("Conflict!")
					if job['max_elev'] > other_job['max_elev']:
						# remove other job
						print("Will remove {} because max elevation is lower. ({} instead of {})".format(other_job['atid'], other_job['max_elev'].rstrip(), job['max_elev'].rstrip()))
						to_remove.append(other_job['atid'])
					else:
						# remove job
						print("Will remove {} because max elevation is the same or lower. ({} instead of {})".format(job['atid'], job['max_elev'].rstrip(), other_job['max_elev'].rstrip()))
						to_remove.append(job['atid'])

	if len(to_remove) > 0:
		# Deduplicate to_remove
		to_remove = list(set(to_remove))
		# remove items
		data = [job for job in data if not job['atid'] in to_remove]
		# generate lines for new queued_jobs file
		print("New job list with conflicts removed")
		new_lines = []
		for job in data:
			line = "{} {} {} {} {}".format(job["atid"],job["satellite_name"],job["start_time"],job["end_time"],job["max_elev"])
			print("\t{}".format(line), end="")
			new_lines.append(line)
		with open("queued_jobs", "w") as file:
			file.writelines(new_lines)
		# remove items from at queue
		for atid in to_remove:
			os.system("atrm {}".format(atid))
	print("Done.")
