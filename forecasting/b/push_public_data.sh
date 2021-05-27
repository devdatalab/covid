#!/bin/bash

# push public covid forecasting partnership data to public dropbox folder.
# note: this only makes sense (1) on Polaris and (2) if you have Rclone configured properly.
# file link: https://www.dropbox.com/s/cuyn0wj6bsuilwq/merged_data.dta?dl=0

# zip up state and dist DTAs and CSVs
cd ~/iec/covid/forecasting/
tar -vczf covid_forecast.tar.gz README.md merged_data_district.dta merged_data_district.csv pred_data_district.dta pred_data_district.csv pred_data_state.dta pred_data_state.csv
cd -

# push to the public data folder
# this will change to AWS eventually
rclone copy ~/iec/covid/forecasting/covid_forecast.tar.gz my_remote:SamPaul/covid_data/forecasts
printf "finished pushing data to dropbox"
