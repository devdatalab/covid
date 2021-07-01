/* This makefile runs all the data construction steps for district-level mortality data */

/* globals that need to be set (use setc covid):
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$covidpub -- processed data used as inputs for COVID variable construction
*/

/***** TABLE OF CONTENTS *****/
/* PART I: Clean raw data */
/* PART II: Append processed data */
/* Part III: Link states and districts to LGD codes and PC11 districts */
/* PART IV: Final cleaning */

/**************************/
/* PART I: Clean raw data */
/**************************/

/* 1(a). District-Level */

/* West Bengal (district level data only available for Kolkata (KMDC)) */
do $ccode/b/clean_kmdc_mort

/* Karnataka (district level data only available for Bangalore (BBMP)) */
do $ccode/b/clean_bbmp_mort

/* Telangana (district level data only available for Hyderabad (GHMC)) */
do $ccode/b/clean_ghmc_mort

/* Tamil Nadu (district level data only available for Chennai) */
do $ccode/b/clean_chennai_mort

/* Madhya Pradesh */
do $ccode/b/clean_mp_mort

/* Assam */
do $ccode/b/clean_assam_mort

/* Bihar */
do $ccode/b/clean_bihar_mort

/* Andhra Pradesh */
do $ccode/b/clean_ap_mort

/* Uttar Pradesh */
do $ccode/b/clean_up_mort

/* Odisha */
do $ccode/b/clean_odisha_mort

/* 1(b). State-level */

/* clean data for Karnataka, Kerala and Tamil Nadu */
do $ccode/b/clean_state_mort

/**********************************/
/* PART II: Append processed data */
/**********************************/

clear

/* append all processed data in PART I - use force option to resolve any string-float inconsistencies */
foreach i in mort_ap mort_assam mort_bbmp mort_bihar mort_chennai mort_ghmc mort_kolkata mort_mp mort_up {

  append using $tmp/`i'.dta, force

}

/***********************************************************************/
/* Part III: Link states and districts to LGD codes and PC11 districts */
/***********************************************************************/

/* create LGD state name variable to merge */
gen lgd_state_name = lower(state)

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* now create an LGD district name variable to merge */
gen lgd_district_name = lower(district)

/* manually change some district names for masala-merge */
replace lgd_district_name = "y.s.r" if lgd_district_name == "ysr kadapa"
replace lgd_district_name = "kamrup metro" if lgd_district_name == "kamrup( m)"
replace lgd_district_name = "bhadohi" if lgd_district_name == "sant ravidas nagar (bhadohi)"

/* save temp file containing names for masala merge */
save $tmp/mort_tmp, replace

/* run masala merge */
keep lgd_state_name lgd_district_name
duplicates drop
masala_merge lgd_state_name using $keys/lgd_district_key, s1(lgd_district_name) minbigram(0.2) minscore(0.6) outfile($tmp/mort_lgd_district)

/* check that all districts were matched to LGD */
count if match_source == 6
if `r(N)' != 0 {
  disp_nice "`r(N)' LGD districts were unmatched"
}

count if match_source != 6
if `r(N)' != 0 {
  disp_nice "`r(N)' LGD districts matched"
}

/* keep master matches - only those names that matched from the master data */
keep if match_source < 7

/* drop redundant variables */
keep lgd_state_name lgd_district_name_using lgd_district_name_master lgd_district_id

/* merge data back in */
ren lgd_district_name_master lgd_district_name
merge 1:m lgd_state_name lgd_district_name using $tmp/mort_tmp
drop _merge

/* now replace the district name with the lgd key name */
drop lgd_district_name
ren lgd_district_name_using lgd_district_name

/* merge with PC11 districts */
merge m:m lgd_state_id lgd_district_id using "$keys/lgd_pc11_district_key.dta"
keep if _merge == 3
drop _merge

/***************************/
/* PART IV: Final cleaning */
/***************************/

/* convert all months to numeric */
float_month, string(month)

/* label variables */
la var lgd_state_name "LGD State name"
la var state "State"
la var district "District"
la var deaths "Total reported deaths - CRS"
la var month "Month"
la var year "Year"

/* drop redundant LGD variables */
drop lgd_district_version lgd_district_name_local

/* order variables */
order lgd_state_id lgd_district_id lgd_state_name lgd_district_name state district

/* save final dataset unique on district-month-year */
save $covidpub/mortality/district_mort_month, replace
export delimited using $covidpub/mortality/csv/district_mort_month.csv, replace
drop lgd*
export delimited using $covidpub/mortality/pc11/pc11_district_mort_month.csv, replace

/*****************************************/
/* Now save the following datasets:      */
/* 1. Dataset unique on district-year    */
/* 2. Dataset unique on state-month-year */
/* 3. Dataset unique on state-year       */
/*****************************************/

/* 1. District-year */

/* collapse on year to obtain dataset unique on district-year */
collapse (sum) deaths, by(lgd_state_id lgd_district_id lgd_state_name lgd_district_name state district year pc11_state_id pc11_district_id pc11_district_name)

/* append Odisha mortality data which is unique on district-year */
append using $tmp/mort_odisha

order lgd_state_id lgd_district_id lgd_state_name lgd_district_name state district deaths year

la var deaths "Total reported deaths - CRS"

/* save dataset unique on district-year */
save $covidpub/mortality/district_mort_year, replace
export delimited using $covidpub/mortality/csv/district_mort_year.csv, replace
drop lgd*
export delimited using $covidpub/mortality/pc11/pc11_district_mort_year.csv, replace

/* 2. State-month-year */

use $covidpub/mortality/district_mort_month, replace

/* drop states for which we don't have data for all districts - Telangana (only Hyderabad), West Bengal (only Kolkata), Tamil Nadu (only Chennai) and Karnataka (only Bangalore) */
drop if (state == "Telangana" | state == "West Bengal" | state == "Tamil Nadu" | state == "Karnataka")

/* collapse on state-month-year */
collapse (sum) deaths, by(lgd_state_id lgd_state_name state month year pc11_state_id)

/* append state-month-year data */
append using $tmp/mort_states

/* label and order variables */
la var deaths "Total reported deaths - CRS"
order lgd_* state deaths month year

/* save dataset unique on state-month-year */
save $covidpub/mortality/state_mort_month, replace
export delimited using $covidpub/mortality/csv/state_mort_month.csv, replace
preserve
drop lgd*
export delimited using $covidpub/mortality/pc11/pc11_state_mort_month.csv, replace
restore

/* 3. State-year */

/* collapse on state-year */
collapse (sum) deaths, by(lgd_state_id lgd_state_name state year pc11_state_id)

/* add odisha year totals */
append using $tmp/mort_odisha_state

/* label and rename variables */
la var deaths "Total reported deaths - CRS"
order lgd_* state deaths year

/* save dataset unique on state-year */
save $covidpub/mortality/state_mort_year, replace
export delimited using $covidpub/mortality/csv/state_mort_year.csv, replace
drop lgd*
export delimited using $covidpub/mortality/pc11/pc11_state_mort_year.csv, replace
