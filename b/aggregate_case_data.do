/* Agregate covid case data to district level */

/**********/
/* Deaths */
/**********/
use $iec/health/covid_data/covid_deaths_recoveries, clear

/* keep only the deaths */
keep if patientstatus == "Deceased"

/* create counter to get total number of deaths */
gen new_deaths = 1

/* collapse to district-day */
collapse (sum) new_deaths, by(pc11_state_id pc11_district_id date)

/* save as a tempfile */
tempfile deaths
save `deaths'

/*********/
/* Cases */
/*********/
use $iec/health/covid_data/covid_raw_data, clear

/* rename date announced to simply date */
ren dateannounced date

/* create counter to get total number of cases */
gen new_cases = 1

/* collapse to district-day */
collapse (sum) new_cases, by(pc11_state_id pc11_district_id date)


/*******************/
/* Merge and Clean */
/*******************/
merge 1:1 pc11_state_id pc11_district_id date using `deaths'

/* fill in missing new_cases and new_deaths with 0 */
replace new_cases = 0 if mi(new_cases)
replace new_deaths = 0 if mi(new_deaths)

/* create a numeric datetime */
gen datenum =  clock(date, "DMY")

/* sort by state, district, and date */
sort pc11_state_id pc11_district_id datenum

/* count the running total of cases*/
bys pc11_state_id pc11_district_id: gen total_cases = sum(new_cases)

/* count the running total of deaths */
bys pc11_state_id pc11_district_id: gen total_deaths = sum(new_deaths)

drop _merge datenum

/* save the district-level data */
save $iec/health/covid_data/covid_cases_deaths_district, replace
