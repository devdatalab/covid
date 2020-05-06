#!/usr/bin/env bash



#############
# ship data #
#############

# send public data folder to Dropbox via rclone (rclone must be configured)
rclone copy --progress ~/iec/covid my_remote:SamPaul/covid_data/


