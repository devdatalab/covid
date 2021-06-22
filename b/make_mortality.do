/* This makefile runs all the data construction steps for district-level mortality data */

/* globals that need to be set:
$tmp -- a temporary folder
$ccode -- this root folder for this repo
$covidpub -- processed data used as inputs for COVID variable construction
*/

/* load covid programs */
do $ddl/covid/covid_progs.do

/**************************/
/* PART I: Clean raw data */
/**************************/

/* West Bengal (district level data only available for Kolkata (KMDC)) */
do $ddl/covid/b/clean_kmdc_mort

/* Karnataka (district level data only available for Bangalore (BBMP)) */
do $ddl/covid/b/clean_bbmp_mort

/* Telangana (district level data only available for Hyderabad (GHMC)) */
do $ddl/covid/b/clean_ghmc_mort

/* Tamil Nadu (district level data only available for Chennai */
do $ddl/covid/b/clean_chennai_mort

/* Madhya Pradesh */
do $ddl/covid/b/clean_mp_mort

/* Assam */
do $ddl/covid/b/clean_assam_mort

/* Bihar */
do $ddl/covid/b/clean_bihar_mort

/* Andhra Pradesh */
do $ddl/covid/b/clean_ap_mort

/**********************************/
/* PART II: Append processed data */
/**********************************/

clear

/* append all processed data in PART I */
foreach i in mort_ap mort_assam mort_bbmp mort_bihar mort_chennai mort_ghmc mort_kolkata mort_mp {

  append using $tmp/`i'.dta, force

}

/**************************************************/
/* PART III: Link to LGD codes and PC11 districts */
/**************************************************/

/* create lgd_state variable to merge */
gen lgd_state_name = lower(state)

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* now create an lgd_district variable to merge */
gen lgd_district_name = lower(district)

/* manually change some district names for masala-merge */
replace lgd_district_name = "y.s.r" if lgd_district_name == "ysr kadapa"
replace lgd_district_name = "kamrup metro" if lgd_district_name == "kamrup( m)"

/* save temp file */
save $tmp/mort_tmp, replace

/* run masala merge */
keep lgd_state_name lgd_district_name
duplicates drop
masala_merge lgd_state_name using $keys/lgd_district_key, s1(lgd_district_name) minbigram(0.2) minscore(0.6) outfile($tmp/mort_lgd_district)

/* check that all districts were matched to LGD */
count if match_source == 6
di "`r(N)' districts were unmatched"

/* keep master matches */
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
la var deaths "Total Deaths"
la var month "Month"
la var year "Year"

/* save final dataset */
save $covidpub/mortality/district_mort, replace
