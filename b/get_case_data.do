/* Get the most up to date case data
data source: https://www.covid19india.org/
direct link to api: https://api.covid19india.org/raw_data.json

This file does the folllowing steps for both case data and death data:
1. Retrieves the most recent case data, labels variables, and saves a full stata file
2. Creates a covid case data - pc11 district key
3. Matches covid case data with pc11 state and districts
*/

/**********************/
/* PREP THE PC11 KEYS */
/**********************/
/* open the pc11 keys */
use $iec/keys/pc11_district_key, clear

/* create a unique string id for masala merge */
gen idu = pc11_state_id + "-" + pc11_district_name

/* save as a tempfile */
save $tmp/pc11_district_pkeys_merge, replace

/******************************/
/* A. PATIENT-LEVEL CASE DATA */
/******************************/
cd $ddl/covid

/* 1. Retrieve the data */
/* call python function to retrieve the patient-level covid data */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_case_data; retrieve_covid19india_case_data('https://api.covid19india.org/raw_data.json', '$tmp')"

/* import the patient data we just pulled */
import delimited using $tmp/covid_raw_data.csv, clear
drop v1

/* drop missing data */
drop if mi(detectedstate)

/* label variables */
label var agebracket "age of person"
label var backupnotes "additional notes on person"
label var currentstatus "clinical status"
label var dateannounced "date case announced"
label var detectedcity "city case detected"
label var detecteddistrict "district case detected"
label var detectedstate "state case detected"
label var estimatedonsetdate ""
label var gender "gender of person"
label var nationality "nationality of person"
label var notes "notes on case"
label var patientnumber "unique patient id"
label var source1 "news source 1 of case"
label var source2 "news source 2 of case"
label var source3 "news source 3 of case"
label var statecode "state abbreviation"
label var statepatientnumber "number patient in state"
label var statuschangedate "date status of person changed"
label var typeoftransmission "transmission to this person"

ren contractedfromwhichpatientsuspec contracted
label var contracted "contact tracing (suspected)"

/* 2. Create pc11/pc01 key */
/* States */
gen pc11_state_name = lower(detectedstate)
replace pc11_state_name = subinstr(pc11_state_name, "and ", "", .)
replace pc11_state_name = "nct of delhi" if pc11_state_name == "delhi"
replace pc11_state_name = itrim(trim(pc11_state_name))

/* merge in pc11_state_id */
merge m:1 pc11_state_name using $iec/keys/pc11_state_key, keepusing(pc11_state_id) keep(match master)

/* replace state id for telangana (AP in 2011) and ladakh (JK in 2011) */
replace pc11_state_id = "28" if detectedstate == "Telangana"
replace pc11_state_id = "01" if detectedstate == "Ladakh"

/* make sure all pc11_state_id's are matched */
qui count if mi(pc11_state_id)
assert `r(N)' == 0
drop _merge

/* save the full raw data in a temp folder, we will come back to merge in pc11 values later */
save $tmp/covid_raw_data, replace

/* Districts */
/* drop missing districts - some observations do not have district data */
drop if mi(detecteddistrict)
gen pc11_district_name = lower(detecteddistrict)

/* keep only unique state-district pairs */
keep pc11_state_id pc11_district_name detectedstate detecteddistrict
duplicates drop

/* create the unique string id for masala merge */
gen idm = pc11_state_id + "-" + pc11_district_name

/* save the raw data key at this point */
save $tmp/covid_raw_data_keys, replace

/* run masala merge */
masala_merge pc11_state_id using $tmp/pc11_district_keys_merge, s1(pc11_district_name) idmaster(idm) idusing(idu) minbigram(0.1) minscore(0.5) manual_file($iec/health/covid_data/manual_covid_case_district_match.csv) nonameclean

/* PAUSE HERE AND ADD CORRECTIONS YOU WANT TO THE UNMATCHED FILE 
   fill in the unmatched observation file name below- unmatched_observations_78494.csv is a placeholder */
cap process_manual_matches, infile($tmp/unmatched_observations_78494.csv) outfile($iec/health/covid_data/manual_covid_case_district_match.csv) s1(pc11_district_name) idmaster(idm_master) idusing(idu_using) charsep("-")

/* re-run masala merge again with manual matches*/
use $tmp/covid_raw_data_keys, clear
masala_merge pc11_state_id using $tmp/pc11_district_keys_merge, s1(pc11_district_name) idmaster(idm) idusing(idu) minbigram(0.1) minscore(0.5) manual_file($iec/health/covid_data/manual_covid_case_district_match.csv) nonameclean
drop pc11_district_name_master
ren pc11_district_name_using pc11_district_name

/* drop unmatched from using */
drop if match_source == 7

/* save the covid case data - pc11 district key */
keep pc11* pc01* detectedstate detecteddistrict
save $iec/health/covid_data/covid_cases_pc11_district_key, replace

/* 3. Match the full case data with the pc11 keys */
use $tmp/covid_raw_data, clear

/* merge with pc11 codes */
merge m:1 pc11_state_id pc11_state_name detecteddistrict using $iec/health/covid_data/covid_cases_pc11_district_key

drop _merge
save $iec/health/covid_data/covid_raw_data, replace


/*******************************/
/* B. PATIENT-LEVEL DEATH DATA */
/********************************/

/* 1. Retrieve the data */
/* call python function to retrieve the deaths & recovered covid data */
shell python -c "from b.retrieve_case_data import retrieve_covid19india_case_data; retrieve_covid19india_case_data('https://api.covid19india.org/deaths_recoveries.json', '$tmp')"

/* import the patient data we just pulled */
import delimited using $tmp/covid_deaths_recoveries.csv, clear
drop v1 patientnumbercouldbemappedlater

/* clean patient status */
replace patientstatus = "Deceased" if patientstatus == "Deceased#"
drop if mi(patientstatus)

/* label variables */
label var agebracket "age of person"
label var city "city of case"
label var date "date data entered"
label var district "district of case"
label var gender "gender of person"
label var nationality "nationality of person"
label var notes "notes on case"
label var patientstatus "status of patient"
label var slno "serial number of patient- used in this dataset only"
label var source1 "news source 1 of case"
label var source2 "news source 2 of case"
label var source3 "news source 3 of case"
label var state "state of case"
label var statecode "state abbreviation"

/* 2. Create pc11/pc01 key */
/* States */
gen pc11_state_name = lower(state)
replace pc11_state_name = subinstr(pc11_state_name, "and ", "", .)
replace pc11_state_name = "nct of delhi" if pc11_state_name == "delhi"
replace pc11_state_name = itrim(trim(pc11_state_name))

/* merge in the state id's  */
merge m:1 pc11_state_name using $iec/keys/pc11_state_key, keepusing(pc11_state_id) keep(match master)

/* replace state id for telangana (AP in 2011) and ladakh (JK in 2011) */
replace pc11_state_id = "28" if state == "Telangana"
replace pc11_state_id = "01" if state == "Ladakh"

/* manual cleaning */
replace pc11_state_id = "32" if state == "Kerala/Puducherry?"

/* make sure all pc11_state_id's are matched */
qui count if mi(pc11_state_id)
assert `r(N)' == 0
drop _merge

/* save the full raw data in a temp folder, we will come back to merge in pc11 values later */
save $tmp/covid_deaths_recoveries, replace

/* Districts */
/* manual cleaning */
replace district = "" if district == "Italians"

/* drop missing districts - some observations do not have district data */
drop if mi(district)
gen pc11_district_name = lower(district)

/* keep only unique state-district pairs */
keep pc11_state_id pc11_district_name state district
duplicates drop

/* create the unique string id for masala merge */
gen idm = pc11_state_id + "-" + pc11_district_name

/* merge with pc11 codes */
save $tmp/covid_deaths_recoveries_key, replace

/* run masala merge */
masala_merge pc11_state_id using $tmp/pc11_district_keys_merge, s1(pc11_district_name) idmaster(idm) idusing(idu) minbigram(0.6) minscore(0.8) nonameclean

/* PAUSE HERE AND ADD CORRECTIONS YOU WANT TO THE UNMATCHED FILE 
   fill in the unmatched observation file name below- unmatched_observations_21647.csv is a placeholder */
cap process_manual_matches, infile($tmp/unmatched_observations_21647.csv) outfile($iec/health/covid_data/manual_covid_case_district_match.csv) s1(pc11_district_name) idmaster(idm_master) idusing(idu_using) charsep("-")

/* re-run masala merge again with manual matches*/
use $tmp/covid_deaths_recoveries_key, clear
masala_merge pc11_state_id using $tmp/pc11_district_keys_merge, s1(pc11_district_name) idmaster(idm) idusing(idu) minbigram(0.1) minscore(0.5) manual_file($iec/health/covid_data/manual_covid_case_district_match.csv) nonameclean

/* keep only the distrcit name we matched to in the key */
drop pc11_district_name_master
ren pc11_district_name_using pc11_district_name

/* drop unmatched from using */
drop if match_source == 7

/* 3. Match the full case data with the pc11 keys */
keep pc11* pc01* state district
save $iec/health/covid_data/covid_deaths_recoveries_pc11_district_key, replace

/* merge in pc11 and pc01 identifiers */
use $tmp/covid_deaths_recoveries, clear
merge m:1 state district using $iec/health/covid_data/covid_deaths_recoveries_pc11_district_key, keep(match master)
drop _merge

save $iec/health/covid_data/covid_deaths_recoveries, replace
