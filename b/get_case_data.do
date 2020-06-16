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
/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/* Added 05/05/2020: pull in case data from covindia.
   Note: as of June 1 2020, covindia is defunct.  We now use covindia data up until April 27
   then use covid19india (crowdsource) data following that date.  We retain the covindia data 
   because the structure of the covindia2019 data changed April 27, making the older data 
   more difficult to make compatible with the current data. */
cd $ddl/covid

/* 1. Retrieve the data from covindia up until April 27 */

/* call python function to retrieve the district-date level covid data 
   Update 06/15/2020: the API is totally defunct and the data is no longer available. 
   We have archived the last data pull from May and stroed in $covidpub */
// shell python -c "from b.retrieve_case_data import retrieve_covindia_case_data; retrieve_covindia_case_data('https://v1.api.covindia.com/covindia-raw-data', '$tmp')"

/* import the archived data */
import delimited $covidpub/covid/raw/covindia-raw-data-archive.csv, clear varn(1)

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

/* replace state names to match cov19india */
replace state = "andaman and nicobar islands" if state == "andaman and nicobar"
replace state = "odisha" if state == "orissa"

/* replace duplicate spellings of pauri garhwal */
replace district = "pauri garhwal" if (district == "garhwal" | district == "garhwa") & state == "uttarakhand"

/* correct internally inconsistent district names */
synonym_fix district, synfile($ddl/covid/b/str/covid_district_fixes.txt) replace

/* create a numerical date field */
gen date_num = date(date, "DMY")

/* keep only data on or before April 26 2020, which has a date_num == 22031 */
keep if date_num <= 22031

/* sort by district and date so we can calculate the running case and death total */
sort state district date_num

/* rename to match the language we use in covid19india data */
ren infected cases
drop time source date_obj

/* count cumulative totals to match covid19india */
bys state district (date_num) : gen cases_total = sum(cases)
bys state district (date_num) : gen death_total = sum(death)

/* restructure date to match cov19india */
split date, p("/")
replace date = date3 + "-" + date2 + "-" + date1
drop date1 date2 date2

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

/* ensure states are consistent across all entries */
replace state = lower(state)
replace district = lower(district)

/* split out dadra and nagar haveli & daman and diu, unkonwn district defaults to daman and diu */
replace state = "daman and diu" if state == "dadra and nagar haveli and daman and diu" & (district == "daman" | district == "diu" | district == "unknown")
replace state = "dadra and nagar haveli" if state == "dadra and nagar haveli and daman and diu" & district == "dadra and nagar haveli"

/* replace unknown or unclassified districts with missing */
replace state = "" if state == "state unassigned"
replace district = "" if district == "unknown"
replace district = "" if district == "bsf camp"
replace district = "" if district == "unassigned"
replace district = "" if district == "airport quarantine"
replace district = "" if district == "other state"
replace district = "" if district == "others state"
replace district = "" if district == "other states"
replace district = "" if district == "foreign evacuees"
replace district = "" if district == "other region"
replace district = "" if district == "italians"
replace district = "" if district == "evacuees"
replace district = "" if district == "railway quarantine"

/* rename variables to clarify meaning */
ren deceased death_total
ren confirmed cases_total

/* drop unneeded variables */
drop v1 notes date_obj

/* correct internally inconsistent district names */
synonym_fix district, synfile($ddl/covid/b/str/cov19india_district_fixes.txt) replace

/* save data */
save $tmp/covid19india_raw_data, replace

/* keep only states and districts to create the covid-lgd key */
keep state district
duplicates drop

/* drop if missing district */
drop if mi(district)

/* save the state and district list */
sort state district
save $covidpub/covid/covid19india_state_district_list, replace

/*************************/
/* Create covid-LGD keys */
/*************************/
/* import the lgd keys to match to */
use $keys/lgd_district_key, clear

/* generate ids */
gen idu = lgd_state_name + "=" + lgd_district_name

/* save for the merge */
save $tmp/lgd_fmm, replace

/* 1. covindia data */
use $covidpub/covid/covindia_state_district_list, clear

/* gen covid state and district */
gen covid_state_name = state
gen covid_district_name = district

/* clean state and district names */
lgd_state_clean covid_state_name
lgd_dist_clean covid_district_name

/* match to lgd-pc11 key */
lgd_state_match state

/* generate id for masala merge */
gen idm = lgd_state_name + "=" + lgd_district_name

/* run masala merge */
masala_merge lgd_state_name using $tmp/lgd_fmm, s1(lgd_district_name) idmaster(idm) idusing(idu) minbigram(0.2) minscore(0.6) outfile($tmp/covindia_lgd_district)

/* keep only master and match data */
keep if match_source < 6

/* save the key */
keep covid_state_name covid_district_name lgd_state_id lgd_district_id lgd_district_name_using
ren lgd_district_name_using lgd_district_name
save $tmp/covindia_lgd_district_key, replace

/* 2. covid19india data */
use $covidpub/covid/covid19india_state_district_list, clear

/* gen covid state and district */
gen covid_state_name = state
gen covid_district_name = district

/* clean state and district names */
lgd_state_clean covid_state_name 
lgd_dist_clean covid_district_name

/* match to lgd-pc11 key */
lgd_state_match state

/* generate id for masala merge */
gen idm = lgd_state_name + "=" + lgd_district_name

/* run masala merge */
masala_merge lgd_state_name using $tmp/lgd_fmm, s1(lgd_district_name) idmaster(idm) idusing(idu) minbigram(0.2) minscore(0.6) outfile($tmp/covid19india_lgd_district)

/* keep only master and match data */
/* 4 districts unmatched - these don't exist in the lgd district key */
keep if match_source < 6

/* save the key */
keep covid_state_name covid_district_name lgd_state_id lgd_district_id lgd_district_name_using
ren lgd_district_name_using lgd_district_name
save $tmp/covid19india_lgd_district_key, replace


/**********************************************/
/* merge the lgd districts into the case data */
/**********************************************/
use $tmp/covindia_raw_data, clear

/* merge in lgd statea */
ren state lgd_state_name
merge m:1 lgd_state_name using $keys/lgd_state_key.dta, keep(match master)
replace lgd_state_name = "not reported" if mi(lgd_state_name)
drop _merge

/* merge in lgd districts */
ren district covid_district_name
merge m:1 lgd_state_id covid_district_name using $tmp/covindia_lgd_district_key, keep(match master) keepusing(lgd_state_id lgd_district_id lgd_district_name)
drop _merge

/* clarify missing districts as not reported */
replace lgd_district_name = "not reported" if mi(lgd_district_name)

/* save covindia data */
save $tmp/covindia_matched_data, replace

/* covid19india data */
use $tmp/covid19india_raw_data, clear
ren state lgd_state_name

/* merge in lgd statea */
merge m:1 lgd_state_name using $keys/lgd_state_key.dta, keep(match master)
replace lgd_state_name = "not reported" if mi(lgd_state_name)
drop _merge

/* merge in lgd districts */
ren district covid_district_name
merge m:1 lgd_state_id covid_district_name using $tmp/covid19india_lgd_district_key, keep(match master) keepusing(lgd_state_id lgd_district_id lgd_district_name)
drop _merge

/* clarify missing districts as not reported */
replace lgd_district_name = "not reported" if mi(lgd_district_name)

/* append covindia data */
append using $tmp/covindia_matched_data
cap drop _merge
drop active recovered

/* sum over any repeated districts */
collapse (sum) cases death, by(date_num lgd_state_id lgd_district_id lgd_state_name lgd_district_name)
sort date_num lgd_state_id lgd_district_id

/* convert to stata date format */
ren date_num date
format date %dM_d,_CY

/* label and clean up */
label var date "case date"
// label var _m_lgd_districts "merge from raw case data to LGD districts"

/* resave the raw data */
compress
save $covidpub/covid/raw/covid_case_data_raw, replace


/*******************************************************/
/* create a square dataset with each district and year */
/*******************************************************/
use $covidpub/covid/raw/covid_case_data_raw, clear

/* make it square */
egen dgroup = group(lgd_state_name lgd_district_name)
fillin date dgroup 

/* set as time series with dgroup */
sort dgroup date
by dgroup: egen day_number = seq()

/* fill in state, district, lgd names within dgroup 
   to install xfill: net install xfill */
xfill lgd_state_name lgd_district_name lgd_state_id lgd_district_id, i(dgroup)

/* create cumulative sums of deaths and infections */
sort dgroup day_number
by dgroup: gen cum_deaths = sum(death)
by dgroup: gen cum_cases = sum(cases)

/* only save the cumulative counts */
drop dgroup _fillin day_number
ren cum_deaths total_deaths
ren cum_cases total_cases

/* order and save */
order lgd_state_id lgd_district_id date lgd_state_name lgd_district_name
drop cases death
compress
save $covidpub/covid/covid_infected_deaths, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths.csv, replace

/* save PC11-identified version --> need to adjust this 06/05/2020 */
convert_ids, from_ids(lgd_state_id lgd_district_id) to_ids(pc11_state_id pc11_district_id) long(date) key($keys/lgd_pc11_district_key_weights.dta) weight_var(lgd_pc11_wt_pop) labels metadata_urls(https://docs.google.com/spreadsheets/d/e/2PACX-1vTKTuciRsUd6pk5kWhlMyhF85Iv5x04b0njSrWzCkaN5IeEZpBwwvmSdw-mUJOp215jBgv2NPMeTHXK/pub?gid=0&single=true&output=csv)
order pc11*, first
save $covidpub/covid/pc11/covid_infected_deaths_pc11, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths_pc11.csv, replace
