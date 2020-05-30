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
/* Added 05/05/2020: pull in case data from covindia. */
cd $ddl/covid

/* 1. Retrieve the data */
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

