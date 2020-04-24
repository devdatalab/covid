/* Agregate covid case data to district level */

/**********/
/* Deaths */
/**********/
use $covidpub/covid/covid_deaths_recoveries, clear

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
use $covidpub/covid/covid_cases_raw, clear

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

/***************************************************************************/
/* Transform into a square dataset with district positive cases and deaths */
/***************************************************************************/

/* drop if we have no date-- hard to know what to do with these */
drop if mi(date)

/* set a missing value for missing districts so they get counted */
replace pc11_district_id = "-99" if mi(pc11_district_id)

/* create a single variable for state-district */
egen sdgroup = group(pc11_state_id pc11_district_id)

/* save the data here */
tempfile all_data
save `all_data'

/* create a key to match sdgroup with the state and district names */
keep sdgroup pc11_state_id pc11_district_id
duplicates drop
tempfile sdgroup_key
save `sdgroup_key'

/* open the full data back up */
use `all_data', clear

/* fill in  non-reporting dates */
fillin date sdgroup

ren date datestr

gen date = date(datestr, "DMY")
format date %d

/* create a sequential date so we can use L for the last date even if not yesterday */
sort sdgroup date
by sdgroup: egen row = seq()

sort sdgroup row
xtset sdgroup row

/* fill in zeroes with the new missing data */
replace new_cases = 0 if mi(new_cases)
replace new_deaths = 0 if mi(new_deaths)
replace total_cases = 0  if datestr == "30/01/2020" & mi(total_cases)
replace total_deaths = 0 if datestr == "30/01/2020" & mi(total_deaths)

/* fill in the cumulative count for days when nothing happened */
replace total_cases = L.total_cases if mi(total_cases)
replace total_deaths = L.total_deaths if mi(total_deaths)

drop _fillin
 
/* merge the missing state and district id's back in */
merge m:1 sdgroup using `sdgroup_key', keep(match master) update nogen

save $covidpub/covid/covid_cases_deaths_district, replace
