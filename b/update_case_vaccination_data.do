/* this file updates just the case count and vaccination data, the most frequently updated files on our platform. */

/* get new case data */
setc covid
do $ccode/b/get_case_data.do
import delimited using $covidpub/covid/csv/covid_infected_deaths.csv, clear

/* check last date */
quietly {
  gen date_fmt = date(date, "DMY")
  egen latest_date = max(date_fmt)
  lab var latest_date "Last Day in the data:"
  format latest_date %td
  noi tab latest_date
}

/* run checks */
is_unique lgd_state_id lgd_state_name lgd_district_name date

/* check that data is square */
gen n = 1
bys lgd_state_id lgd_state_name lgd_district_name: egen num_days = total(n)
qui distinct num_days
local square_check =  `r(ndistinct)'
if `square_check' != 1 {
  disp_nice "Data is not square, it should have the same number of observations (days) for each district."
  exit 9
}

/* get new vaccination data */
do $ccode/b/get_vaccination_data.do

/* import the csv data */
import delimited using $covidpub/covid/csv/covid_vaccination.csv, clear

/* check last date */
quietly {
  gen date_fmt = date(date, "DMY")
  egen latest_date = max(date_fmt)
  lab var latest_date "Last Day in the data:"
  format latest_date %td
  noi tab latest_date
}

/* run checks */
is_unique lgd_state_id lgd_state_name lgd_district_name date

/* check that data is square */
gen n = 1
bys lgd_state_id lgd_state_name lgd_district_name: egen num_days = total(n)
qui distinct num_days
local square_check =  `r(ndistinct)'
if `square_check' != 1 {
  disp_nice "Data is not square, it should have the same number of observations (days) for each district."
  exit 9
}

/* check how many days are in the data - should be more than 97 as of 23 april 2021 */
qui sum num_days
local num_days = `r(mean)'
if `num_days' < 97 {
  disp_nice "Data is missing. There should be more than 97 days of data."
  exit 9
}

/* rclone needed data files to dropbox. CSV first */
shell rclone copyto --progress ~/iec/covid/covid/csv/covid_infected_deaths.csv my_remote:SamPaul/covid_data/covid/csv/covid_infected_deaths.csv
shell rclone copyto --progress ~/iec/covid/covid/csv/covid_infected_deaths_pc11.csv my_remote:SamPaul/covid_data/covid/csv/covid_infected_deaths_pc11.csv
shell rclone copyto --progress ~/iec/covid/covid/csv/covid_vaccination.csv my_remote:SamPaul/covid_data/covid/csv/covid_vaccination.csv

/* now dta */
shell rclone copyto --progress ~/iec/covid/covid/covid_infected_deaths.dta my_remote:SamPaul/covid_data/covid/covid_infected_deaths.dta
shell rclone copyto --progress ~/iec/covid/covid/covid_infected_deaths_pc11.dta my_remote:SamPaul/covid_data/covid/covid_infected_deaths_pc11.dta
shell rclone copyto --progress ~/iec/covid/covid/covid_vaccination.dta my_remote:SamPaul/covid_data/covid/covid_vaccination.dta
