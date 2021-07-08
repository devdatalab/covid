/*******************************************/
/* Clean Mortality data for several states */
/*******************************************/

/************************************************************/
/* Data for the following states is cleaned in this script: */
/* 1. Kerala                                                */
/* 2. Karnataka                                             */
/* 3. Tamil Nadu                                            */
/************************************************************/

/****************/
/* Clean Kerala */
/****************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/kerala.xlsx", sheet("Sheet2") cellrange(A3:H14) clear

/* rename variables for reshape */
ren A month
ren B deaths2015
ren C deaths2016
ren D deaths2017
ren E deaths2018
ren F deaths2019
ren G deaths2020
ren H deaths2021

/* reshape from wide to long on deaths */
reshape long deaths, i(month) j(year)

/* drop missing data */
drop if deaths == 0

/* generate state variable */
gen state = "Kerala"

/* add contributor */
note deaths: Source data for Kerala provided by NewsMinute

/* save clean data to scratch */
save $tmp/mort_kerala, replace

/*******************/
/* Clean Karnataka */
/*******************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/Karnataka, BBMP deaths data.xlsx", sheet("Sheet1") cellrange(A4:H15) clear

/* rename variables for reshape */
ren A month
ren B deaths2015
ren C deaths2016
ren D deaths2017
ren E deaths2018
ren F deaths2019
ren G deaths2020
ren H deaths2021

/* reshape from wide to long on deaths */
reshape long deaths, i(month) j(year)

/* generate state variable */
gen state = "Karnataka"

/* drop missing data */
drop if mi(deaths)

/* save clean data to scratch */
save $tmp/mort_karnataka, replace

/********************/
/* Clean Tamil Nadu */
/********************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/crs_tamil_nadu.xlsx", sheet("Monthwise occurrence of Deaths") cellrange(A4:E15) clear

/* rename variables for reshape */
ren A month
ren B deaths2018
ren C deaths2019
ren D deaths2020
ren E deaths2021

/* reshape from wide to long on deaths */
reshape long deaths, i(month) j(year)

/* drop missing data */
drop if mi(deaths)

/* generate state variable */
gen state = "Tamil Nadu"

/* add contributor */
note deaths: Source data for Tamil Nadu provided by Rukmini S 

/* save clean data to scratch */
save $tmp/mort_tn, replace

/*************************/
/* Append all state data */
/*************************/

/* append kerala */
append using $tmp/mort_kerala

/* append karnataka */
append using $tmp/mort_karnataka

/**********************************/
/* Link to LGD + PC11 identifiers */
/**********************************/ 

/* create lgd_state variable to merge */
gen lgd_state_name = lower(state)

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* merge with PC11 states and drop extraneous LGD identifiers */
merge m:m lgd_state_id using "$keys/lgd_pc11_state_key.dta"
keep if _merge == 3
drop _merge lgd_state_name_local lgd_state_version lgd_state_status

/*****************/
/* Final cleanup */
/*****************/

/* convert months from string to float */
replace month = lower(month)
float_month, string(month)

la var deaths "Total reported deaths - CRS"

order lgd_* deaths month year pc11_*

/* save clean dataset to scratch */
save $tmp/mort_states, replace
