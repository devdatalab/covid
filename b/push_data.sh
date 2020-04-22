#!/usr/bin/env bash

############
# Preamble #
############

# use rclone to push data to the cloud. rclone shared install in ~/iec/local/bin/rclone
# wiki on rclone config: https://github.com/devdatalab/tools/wiki/rclone

#########################
# Zip and ship raw data #
#########################

# cp input data from section 1 of make_covid.do to a temp folder to avoid including paths in the archive
mkdir -p ~/covid_tmp/input
cp -t ~/covid_tmp/input ~/iec/health/DLHS4_FacilitySurveyData/dlhs4_district_key.dta ~/iec/shrug_covid/dlhs4_hospitals_dist.dta ~/iec/shrug_covid/pc11u_hosp.dta ~/iec/shrug_covid/pc11r_hosp.dta ~/iec/shrug_covid/ec13_hosp_microdata.dta

# create tarball of input data (from the first section of make_covid.do)
tar cvzf ~/ddl_covid_input_data.tar.gz -C ~/covid_tmp/input/ .

# cp processed data from the latter sections of make_covid.do to a different subfolder
mkdir ~/covid_tmp/output
cp -t ~/covid_tmp/output ~/iec/shrug_covid/pc_hospitals_subdist.dta ~/iec/shrug_covid/pc_hospitals_dist.dta ~/iec/shrug_covid/ec_hospitals_tv.dta ~/iec/shrug_covid/ec_hospitals_dist.dta ~/iec/health/hosp/hospitals_dist_export.dta ~/iec/shrug_covid/out/district_age_dist_cfr_hospitals.dta

# create tarball of output data
tar cvzf ~/ddl_covid_output_data.tar.gz -C ~/covid_tmp/output/ .

# send tarballs to Dropbox via rclone (rclone must be configured)
rclone copy --progress ~/ddl_covid_input_data.tar.gz my_remote:SamPaul/covid_data/
rclone copy --progress ~/ddl_covid_output_data.tar.gz my_remote:SamPaul/covid_data/

# remove copied data and containing tmp folder
rm -rf ~/covid_tmp/

# remove tarballs
rm -f ~/ddl_covid_input_data.tar.gz ~/ddl_covid_output_data.tar.gz


