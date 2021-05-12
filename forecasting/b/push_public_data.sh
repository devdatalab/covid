#!/bin/bash

# push public covid forecasting partnership data to public dropbox folder.
# note: this only makes sense (1) on Polaris and (2) if you have Rclone configured properly.
# file link: https://www.dropbox.com/s/cuyn0wj6bsuilwq/merged_data.dta?dl=0

# push to the public data folder
# this will change to AWS eventually
rclone copy ~/iec/covid/forecasting/merged_data.dta my_remote:SamPaul/covid_data/forecasts
printf "finished pushing data to dropbox"
