#!/usr/bin/env bash


############
# Preamble #
############

# Note that this script uses the csv2md utility, which is most easily installed into a conda env
#conda install -c anaconda pip
#pip install csv2md

# we use rclone to push data to the cloud. 

# remove any existing data descriptions and metadata from the end of the readme
sed -i '/<!--- begin data and metadata descriptions - do not edit this comment -->/q' ~/ddl/covid/assets/metadata.md


###############
# PC Metadata #
###############

# initialize section for PC in the metadata list
echo "## Population Census " >> ~/ddl/covid/assets/metadata.md
echo "### Dataset-level Metadata  " >> ~/ddl/covid/assets/metadata.md

# pull dataset-level PC hospitals metadata fromm google sheet and ensure unix linebreaks
wget -O ~/pc_dataset_metadata.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pub?gid=1661733111&single=true&output=csv"

# parse this into a metadata markdown table, and append to the readme
csv2md ~/pc_dataset_metadata.csv >> ~/ddl/covid/assets/metadata.md

# same steps for variable-level metadata
echo "### Variable-level Metadata  " >> ~/ddl/covid/assets/metadata.md
wget -O ~/pc_variable_metadata.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vTpGgFszhHhMlzh-ePv3tRj5Arpv7uyicPPDgkCS7-Ms3nE6OvofQWBFuOxOWBPtELzSmBFttxvLc20/pub?gid=1900447643&single=true&output=csv"
csv2md ~/pc_variable_metadata.csv >> ~/ddl/covid/assets/metadata.md


#################
# DLHS Metadata #
#################

# initialize section for PC in the metadata list
echo "## DLHS " >> ~/ddl/covid/assets/metadata.md
echo "### Dataset-level Metadata  " >> ~/ddl/covid/assets/metadata.md

# dataset-level metadata
wget -O ~/dlhs_dataset_metadata.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vR8pkaS86ZlwcSe0ljKyL6wR_YOGE380JrHgAhG5Z66Oq1WtD4xtsJCsdCt-yAv8Qw0X74twBeIQ9of/pub?gid=1661733111&single=true&output=csv"

# parse this into a metadata markdown table, and append to the readme
csv2md ~/dlhs_dataset_metadata.csv >> ~/ddl/covid/assets/metadata.md

# variable-level metadata
echo "### Variable-level Metadata  " >> ~/ddl/covid/assets/metadata.md
wget -O ~/dlhs_variable_metdata.csv "https://docs.google.com/spreadsheets/d/e/2PACX-1vR8pkaS86ZlwcSe0ljKyL6wR_YOGE380JrHgAhG5Z66Oq1WtD4xtsJCsdCt-yAv8Qw0X74twBeIQ9of/pub?gid=1900447643&single=true&output=csv"
csv2md ~/dlhs_variable_metdata.csv >> ~/ddl/covid/assets/metadata.md


#########################
# Zip and ship raw data #
#########################

# cp input data from section 1 of make_covid.do to a temp folder to
# avoid including paths in the archive. copy metadata as well.
mkdir -p ~/covid_tmp/input
cp -t ~/covid_tmp/input ~/iec/health/DLHS4_FacilitySurveyData/dlhs4_district_key.dta ~/iec/shrug_covid/dlhs4_hospitals_dist.dta ~/iec/shrug_covid/pc11u_hosp.dta ~/iec/shrug_covid/pc11r_hosp.dta ~/iec/shrug_covid/ec_hosp_microdata.dta
cp -t ~/covid_tmp/input ~/dlhs*metadata.csv ~/pc*metadata.csv

# create tarball of input data (from the first section of make_covid.do)
tar cvzf ~/ddl_covid_input_data.tar.gz -C ~/covid_tmp/input/ .

# cp processed data from the latter sections of make_covid.do to a different subfolder
mkdir ~/covid_tmp/output
cp -t ~/covid_tmp/output ~/iec/shrug_covid/pc_hospitals_subdist.dta ~/iec/shrug_covid/pc_hospitals_dist.dta ~/iec/shrug_covid/ec_hospitals_tv.dta ~/iec/shrug_covid/ec_hospitals_dist.dta ~/iec/health/hosp/hospitals_dist_export.dta ~/iec/shrug_covid/out/district_age_dist_cfr_hospitals.dta
cp -t ~/covid_tmp/output ~/dlhs*metadata.csv ~/pc*metadata.csv

# create tarball of output data
tar cvzf ~/ddl_covid_output_data.tar.gz -C ~/covid_tmp/output/ .

# send tarballs to Dropbox via rclone (rclone must be configured)
rclone copy --progress ~/ddl_covid_input_data.tar.gz my_remote:SamPaul/covid_data/
rclone copy --progress ~/ddl_covid_output_data.tar.gz my_remote:SamPaul/covid_data/


###########
# Cleanup #
###########

# remove copied data and containing tmp folder
rm -rf ~/covid_tmp/

# remove tarballs
rm -f ~/ddl_covid_input_data.tar.gz ~/ddl_covid_output_data.tar.gz
