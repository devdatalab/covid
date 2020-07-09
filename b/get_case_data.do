/* Get the most up to date case data
data source: www.covid19india.org
direct links to api: https://api.covid19india.org/

1a. Retrieve pre-April 27 raw case data, aggregate to district-day
1b. Retrieve pre-April 27 raw death data, aggregate to district-day
2. Retrieve post-April 27 district-day data
3. Create covid-LGD district keys
4. Standardize all data to LGD districts
*/

/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/*******************************************/
/* 1a. Retrieve the pre-April 27 case data */
/*******************************************/
/* call python function to retrieve the patient-level covid data */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_case_data; retrieve_covid19india_case_data('https://api.covid19india.org/raw_data.json', '$tmp')"

/* import the patient data we just pulled */
import delimited using $tmp/covid19india_old_cases.csv, clear

/* create date object from date string */
gen date2 = date(date, "YMD")
drop date
ren date2 date
format date %td

/* rename variables */
ren detectedstate state
ren detecteddistrict district
ren numcases cases

/* ensure states are consistent across all entries */
replace state = lower(state)
replace district = lower(district)

/* replace missing districts */
replace district = "" if district == "other state"
replace district = "" if district == "other region"
replace district = "" if district == "evacuees"
replace district = "" if district == "italians"

/* drop "correction for district count" - these sum to 0 and appear to be some bookkeeping mechanism to shift allocation of cases,
   overall it's unclear how we should use these counts so we drop them (having no effect on the overall case count)  */
drop if notes == "Correction for district count"

/* only keep necessary informatoin */
keep date state district cases

/* drop if missing date  */
drop if mi(date)

/* drop if missing state- this is just one case that is missing both */
drop if mi(state)

/* correct internally inconsistent district names */
synonym_fix district, synfile($ddl/covid/b/str/cov19india_district_fixes.txt) replace

/* fill in not reported districts */
replace district = "not reported" if mi(district)

/* collapse to district level */
collapse (sum) cases, by(state district date)

/* make it square */
egen dgroup = group(state district)
fillin date dgroup 

/* set as time series with dgroup */
sort dgroup date

/* fill in state, district, lgd names within dgroup 
   to install xfill: net install xfill */
xfill state district, i(dgroup)
sort dgroup date
drop dgroup _fillin

/* save pre-April 27 case data */
save $tmp/old_covid19_case_data, replace

/********************************************/
/* 1b. Retrieve the pre-April 27 death data */
/********************************************/
/* call python function to retrieve the deaths & recovered covid data */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_deaths_data; retrieve_covid19india_deaths_data('https://api.covid19india.org/deaths_recoveries.json', '$tmp')"

/* import the patient data we just pulled */
import delimited using $tmp/covid19india_old_deaths.csv, clear

/* create date object from date string */
gen date2 = date(date, "YMD")
drop date
ren date2 date
format date %td

/* ensure states are consistent across all entries */
replace state = lower(state)
replace district = lower(district)

/* replace missing districts */
replace district = "" if district == "other state"
replace district = "" if district == "other region"
replace district = "" if district == "evacuees"
replace district = "" if district == "italians"

/* keep only deceased patient status */
keep if patientstatus == "Deceased"

/* count everyone as a death */
gen death = 1

/* keep only necessary data */
keep date state district death

/* correct internally inconsistent district names */
synonym_fix district, synfile($ddl/covid/b/str/cov19india_district_fixes.txt) replace

/* fill in not reported districts */
replace district = "not reported" if mi(district)

/* collapse to district level */
collapse (sum) death, by(state district date)

/* make it square */
egen dgroup = group(state district)
fillin date dgroup 

/* fill in state, district, lgd names within dgroup 
   to install xfill: net install xfill */
xfill state district, i(dgroup)
drop dgroup _fillin

/* merge the old case and death data */
merge 1:1 state district date using $tmp/old_covid19_case_data
drop _merge

/* get the total case and death count - first create state-district groups*/
egen dgroup = group(state district)

/* ensure data is sorted by dgroup and date */
sort dgroup date

/* count the cumulative totals for deaths and cases */
bys dgroup (date): gen death_total = sum(death)
bys dgroup (date): gen cases_total = sum(cases)

/* drop the daily counts of deaths and cases, keeping only the totals */
drop dgroup death cases

/* save old data */
save $tmp/all_old_covid19_data, replace

/* keep only the states and districts for the key */
keep state district
duplicates drop 

/* drop if missing district */
drop if district == "not reported"

/* save for the key */
save $tmp/all_old_covid19_key, replace

/****************************************************/
/* 2. Retrieve the post-April 27 district case data */
/****************************************************/
cd $ddl/covid

/* define the url and pull the data files from covid19india */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_district_data; retrieve_covid19india_district_data('https://api.covid19india.org/districts_daily.json', '$tmp')"

/* read in the data */
import delimited using $tmp/covid19india_district_data.csv, clear

/* create date object from date string */
gen date2 = date(date, "YMD")
drop date
ren date2 date
format date %td
drop if mi(date)

/* drop the few datapoints before April 27, these are data entry errors */
drop if date <= 22031
sort state district date

/* ensure states are consistent across all entries */
replace state = lower(state)
replace district = lower(district)

/* split out dadra and nagar haveli & daman and diu, unkonwn district defaults to daman and diu */
replace state = "daman and diu" if state == "dadra and nagar haveli and daman and diu" & (district == "daman" | district == "diu" | district == "unknown" | district == "other state")
replace state = "dadra and nagar haveli" if state == "dadra and nagar haveli and daman and diu" & district == "dadra and nagar haveli"

/* replace unknown or unclassified districts with missing */
replace state = "" if state == "state unassigned"
replace district = "" if district == "unknown"
replace district = "" if district == "other"
replace district = "" if district == "others"
replace district = "" if district == "ndrf-odrf"
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

/* fill in not reported districts */
replace district = "not reported" if mi(district)

/* collapse to district level */
collapse (sum) cases_total death_total, by(state district date)

/* make it square */
egen dgroup = group(state district)
fillin date dgroup 

/* fill in state, district, lgd names within dgroup 
   to install xfill: net install xfill */
xfill state district, i(dgroup)
sort dgroup date
drop dgroup _fillin

/* fill in the missing death and cases values with 0 (these are from preceding dates with no cases reported) */
replace death_total = 0 if mi(death_total)
replace cases_total = 0 if mi(cases_total)

/* save data */
save $tmp/covid19india_raw_data, replace

/* keep only states and districts to create the covid-lgd key */
keep state district

/* drop if missing district */
drop if district == "not reported"
duplicates drop

/* save the state and district list */
sort state district
save $covidpub/covid/covid19india_state_district_list, replace

/****************************/
/* 3. Create covid-LGD keys */
/****************************/
/* import the lgd keys to match to */
use $keys/lgd_district_key, clear

/* generate ids */
gen idu = lgd_state_name + "=" + lgd_district_name

/* save for the merge */
save $tmp/lgd_fmm, replace

/* 3a. pre-April 27 data */
use $tmp/all_old_covid19_key, clear

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
save $tmp/old_covid19_lgd_district_key, replace

/* 3b. post-April 27 data */
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

/*********************************/
/* 4. Standardize all covid data */
/*********************************/
use $tmp/all_old_covid19_data, clear

/* merge in lgd states */
ren state lgd_state_name
merge m:1 lgd_state_name using $keys/lgd_state_key.dta, keep(match master)
replace lgd_state_name = "not reported" if mi(lgd_state_name)
drop _merge

/* merge in lgd districts */
ren district covid_district_name
merge m:1 lgd_state_id covid_district_name using $tmp/old_covid19_lgd_district_key, keep(match master) keepusing(lgd_state_id lgd_district_id lgd_district_name)
drop _merge

/* clarify missing districts as not reported */
replace lgd_district_name = "not reported" if mi(lgd_district_name)

/* save old covid19 data */
save $tmp/old_covid19_matched_data, replace

/* covid19india data */
use $tmp/covid19india_raw_data, clear
ren state lgd_state_name

/* merge in lgd states */
merge m:1 lgd_state_name using $keys/lgd_state_key.dta, keep(match master)
replace lgd_state_name = "not reported" if mi(lgd_state_name)
drop _merge

/* merge in lgd districts */
ren district covid_district_name
merge m:1 lgd_state_id covid_district_name using $tmp/covid19india_lgd_district_key, keep(match master) keepusing(lgd_state_id lgd_district_id lgd_district_name)
drop _merge

/* clarify missing districts as not reported 
   note: two reported districts in jammu and kashmir are not represented in LGD (muzaffarabad and mirpir), for now we put them under "not reported" */
replace lgd_district_name = "not reported" if mi(lgd_district_name)

/* append covindia data */
append using $tmp/old_covid19_matched_data

/* sum over any repeated districts */
collapse (sum) cases_total death_total, by(date lgd_state_id lgd_district_id lgd_state_name lgd_district_name)
sort lgd_state_name lgd_district_name date

/* label and clean up */
label var date "case date"
// label var _m_lgd_districts "merge from raw case data to LGD districts"

/* resave the raw data */
compress
save $covidpub/covid/raw/covid_case_data_raw, replace

/* ensure data is square with each district and day */
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

/* fill in missing total death and total cases with 0- these are days preceding the first reports for a given district */
replace cases_total = 0 if mi(cases_total)
replace death_total = 0 if mi(death_total)

/* only save the cumulative counts */
drop dgroup _fillin day_number

/* rename variables to match standard names we are using */
ren cases_total total_cases
ren death_total total_deaths

/* order and save */
order lgd_state_id lgd_district_id date lgd_state_name lgd_district_name date cases_total death_total
compress
save $covidpub/covid/covid_infected_deaths, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths.csv, replace

/* save PC11-identified version --> need to adjust this 06/05/2020 */
convert_ids, from_ids(lgd_state_id lgd_district_id) to_ids(pc11_state_id pc11_district_id) long(date) key($keys/lgd_pc11_district_key_weights.dta) weight_var(lgd_pc11_wt_pop) labels metadata_urls(https://docs.google.com/spreadsheets/d/e/2PACX-1vTKTuciRsUd6pk5kWhlMyhF85Iv5x04b0njSrWzCkaN5IeEZpBwwvmSdw-mUJOp215jBgv2NPMeTHXK/pub?gid=0&single=true&output=csv)
order pc11*, first
save $covidpub/covid/pc11/covid_infected_deaths_pc11, replace
export delimited using $covidpub/covid/csv/covid_infected_deaths_pc11.csv, replace
