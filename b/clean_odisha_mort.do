/*******************************/
/* Clean Odisha Mortality Data */
/*******************************/

/* to be appended with district-year mortality dataset */

/* import raw data */
import excel "$covidpub/private/mortality/raw/Odisha Analysis.xlsx", sheet("CRS") cellrange(B5:N34) clear

/* drop redundant variables and rename them for reshape */
drop F G H I K L M

ren B district
ren C deaths2017
ren D deaths2018
ren E deaths2019
ren J deaths2020
ren N deaths2021

/* reshape from wide to long on deaths */
reshape long deaths, i(district) j(year)

/* generate variable for state */
gen state = "Odisha"

/* create lgd_state variable to merge */
gen lgd_state_name = lower(state)

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* now create an lgd_district variable to merge */
gen lgd_district_name = lower(district)

/* save temp file */
save $tmp/mort_odisha, replace

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
merge 1:m lgd_state_name lgd_district_name using $tmp/mort_odisha
drop _merge

/* now replace the district name with the lgd key name */
drop lgd_district_name
ren lgd_district_name_using lgd_district_name

/* merge with PC11 districts */
merge m:m lgd_state_id lgd_district_id using "$keys/lgd_pc11_district_key.dta"
keep if _merge == 3
drop _merge lgd_district_name_local lgd_district_version
la var deaths "Total reported deaths - CRS"

/* add some pointers about data */
notes deaths: Data for Odisha provided by Chinmay Tumbe (IIM Ahmedabad)
notes death: For Odisha, 2020 deaths are projected totals computed based on average growth factor of 2018 and 2019

order lgd_state_id lgd_district_id lgd_state_name lgd_district_name state district deaths year pc11_*

/* save clean district-year data to scratch */
save $tmp/mort_odisha_dist, replace

/* collapse on state-year */
collapse (sum) deaths, by(lgd_state_id lgd_state_name state year pc11_state_id)

/* save clean state-year data to scratch */
save $tmp/mort_odisha_state, replace
