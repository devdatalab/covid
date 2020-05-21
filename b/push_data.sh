
#!/usr/bin/env bash



#############
# ship data #
#############

# set list of folders to be pushed from $covidpub (not all folders will be shared)
dirs="covid demography estimates hospitals keys migration"

# send public data from these folders to Dropbox via rclone (rclone must be configured)
for dir in $dirs; do
  rclone copy --progress ~/iec/covid/$dir my_remote:SamPaul/covid_data/$dir/
done

