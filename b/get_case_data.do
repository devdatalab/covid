/* Get the most up to date case data
data source: https://covindia.com/
direct link to api: https://v1.api.covindia.com/covindia-raw-data

This file does the following steps for both case data and death data:
1. Retrieves the most recent case data, labels variables, and saves a full stata file
2. Creates a covid case data - pc11 district key
3. Matches covid case data with pc11 state and districts
*/


/********************************/
/* COMBINED CASE AND DEATH DATA */
/********************************/
/* Added 05/05/2020: pull in case data from covindia.
   Note: as of June 1 2020, covindia is defunct.  We now use covindia data up until April 27
   then use covid19india (crowdsource) data following that date.  We retain the covindia data 
   because the structure of the covindia2019 data changed April 27, making the older data 
   more difficult to make compatible with the current data. */
cd $ddl/covid

/* 1. Retrieve the data from covindia up until April 27 */

/* call python function to retrieve the district-date level covid data */
shell python -c "from b.retrieve_case_data import retrieve_covindia_case_data; retrieve_covindia_case_data('https://v1.api.covindia.com/covindia-raw-data', '$tmp')"

/* import the data we just pulled */
import delimited $tmp/covindia-raw-data, clear varn(1)

/* drop the python date object column */
drop date_obj

/* label variables - according to data definitions:
   https://covindia-api-docs.readthedocs.io/en/latest/api-reference/ */
label var date "date of case dd/mm/yyyy"
label var time "time of the report hh:mm, if known"
label var district "the name of the district"
label var state "the name of the state"
label var infected "the number of infected cases in this entry (report)"
label var death "the number of deaths in this entry (report)"
label var source "the source link for this entry (report)"

/* replace missind district code with missing */
replace district = "" if district == "DIST_NA"

/* remove underscores from district names */
replace district = subinstr(district, "_", " ", .)

/* make state and district lower case */
replace district = trim(lower(district))
replace state = trim(lower(state))

/* correct internal misspellings of districts */
synonym_fix district, synfile($ddl/covid/b/str/covid_district_fixes.txt) replace

/* create a numerical date field */
gen date_num = date(date, "DMY")

/* keep only data on or before April 26 2020, which has a date_num == 22031 */
keep if date_num <= 22031

/* rename to match the language we use in covid19india data */
ren infected cases
drop time source

/* sort by district */
sort state district date_num

/* count cumulative totals to match covid19india */
bys state district (date_num) : gen cases_total = sum(cases)
bys state district (date_num) : gen death_total = sum(death)

/* restructure date to match cov19india */
split date, p("/")
replace date = date3 + "-" + date2 + "-" + date1
drop date1 date2 date2

/* replace state names to match cov19india */
replace state = "andaman and nicobar islands" if state == "andaman and nicobar"
replace state = "odisha" if state == "orissa"

/* save data */
save $tmp/covindia_raw_data, replace

/* 2. Retrieve the data from covid19india for all dates April 27 onwards */

/* define the url and pull the data files from covid19india */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_district_data; retrieve_covid19india_district_data('https://api.covid19india.org/districts_daily.json', '$tmp')"

/* read in the data */
import delimited using $tmp/covid19india_district_data.csv, clear

/* create numerical date */
gen date_num = date(date, "YMD")
drop if mi(date)

/* drop the few datapoints before April 27, these are data entry errors */
drop if date_num <= 22031
sort date_num state district

/* 3. Combine covindia and covid2019india data */
replace state = lower(state)
replace state = "dadra and nagar haveli and daman and diu" if state == "dadra and nagar haveli"
replace district = lower(district)

/* correct internally inconsistent district names */
synonym_fix district, synfile($ddl/covid/b/str/cov19india_district_fixes.txt) replace

ren deceased death_total
ren confirmed cases_total

/* drop unneeded variables */
drop v1 notes date_obj

/* append the covindia data */
append using $tmp/covindia_raw_data

/* sort */
sort date_num state district

/* save data */
save $tmp/covindia_raw_data, replace

/* keep only states and districts to create the covid-lgd key */
keep state district
duplicates drop

/* drop if missing district */
drop if mi(district)

/* save the state and district list */
sort state district
save $covidpub/covid/covindia_state_district_list, replace

/****************************************************/
/* matching covindia state district key to lgd-pc11 */
/****************************************************/

/* import data */
use $covidpub/covid/covindia_state_district_list, clear

/* gen covid state and district */
gen covid_state_name = state
gen covid_district_name = district

/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do

/* clean state and district names */
lgd_state_clean state
lgd_dist_clean district

/* match to lgd-pc11 key */
lgd_state_match state
/* note covindia key doesn't have chandigarh */

lgd_dist_match district
/* 2 districts don't match - pak occupied kashmir, and phule (dup obs) */

/* save the key */
save $tmp/covindia_lgd_district_key, replace

/**********************************************/
/* merge the lgd districts into the case data */
/**********************************************/
/* drop the only district (warangal rural) that has multiple covid districts mapping to a single lgd district */
drop if lgd_district_id == "522"

/* save as a temporary file */
save $tmp/covid_key_tmp, replace

/* open the case data */
use $tmp/covindia_raw_data, clear

/* rename state and district */
ren state covid_state_name
ren district covid_district_name

/* merge in the lgd districts */
merge m:1 covid_state_name covid_district_name using $tmp/covid_key_tmp, keep(match master) keepusing(lgd_state_id lgd_district_id) gen(_m_lgd_districts)

/* convert to stata date format */
gen tmp = date(date, "DMY")
drop date
ren tmp date
format date %dM_d,_CY

/* drop duplicates, with a magnitude assertion. these are dups across all fields, which add no value. */
qui count
local denom = `r(N)'
duplicates drop
qui count
local num = `r(N)'
assert `num' / `denom' > 0.99

/* label and clean up */
label var date "case date"
label var _m_lgd_districts "merge from raw case data to LGD districts"
compress

/* resave the raw data */
save $covidpub/covid/raw/covindia_raw, replace

/* create a square dataset with each district and year */
use $covidpub/covid/raw/covindia_raw, clear

/* clarify when district names are missing */
replace covid_district_name = "not reported" if mi(covid_district_name)

/* collapse to one report per district / date */
collapse (firstnm) lgd_state_id lgd_district_id (sum) death infected, by(covid_state_name covid_district_name date)

/* make it square */
egen dgroup = group(covid_state_name covid_district_name)
fillin date dgroup 

/* set as time series with dgroup */
sort dgroup date
by dgroup: egen day_number = seq()

/* fill in state, district, lgd names within dgroup */
xfill covid_state_name covid_district_name lgd_state_id lgd_district_id, i(dgroup)

/* create cumulative sums of deaths and infections */
sort dgroup day_number
by dgroup: gen cum_deaths = sum(death)
by dgroup: gen cum_infected = sum(infected)

/* only save the cumulative counts */
drop death infected dgroup _fillin day_number
ren cum_deaths total_deaths
ren cum_infected total_cases

/* order and save */
order lgd_state_id lgd_district_id date covid_state_name covid_district_name
compress
save $covidpub/covid/covid_infected_deaths, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths.csv, replace

/* save PC11-identified version */
convert_ids, from_ids(lgd_state_id lgd_district_id) to_ids(pc11_state_id pc11_district_id) long(covid_state_name covid_district_name date) key($keys/lgd_pc11_district_key_weights.dta) weight_var(lgd_pc11_wt_pop) labels metadata_urls(https://docs.google.com/spreadsheets/d/e/2PACX-1vTKTuciRsUd6pk5kWhlMyhF85Iv5x04b0njSrWzCkaN5IeEZpBwwvmSdw-mUJOp215jBgv2NPMeTHXK/pub?gid=0&single=true&output=csv)
order pc11*, first
save $covidpub/covid/pc11/covid_infected_deaths_pc11, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths_pc11.csv, replace

