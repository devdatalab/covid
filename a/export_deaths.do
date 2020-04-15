/* export death data for anup */
use ~/iec/health/covid_data/covid_cases_deaths_district, clear

/* drop if we have no date-- hard to know what to do with these */
drop if mi(date)

/* set a missing value for missing districts so they get counted */
replace pc11_district_id = "-99" if mi(pc11_district_id)

/* create a single variable for state-district */
egen sdgroup = group(pc11_state_id pc11_district_id)

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

replace new_cases = 0 if mi(new_cases)
replace new_deaths = 0 if mi(new_deaths)
replace total_cases = 0  if datestr == "30/01/2020" & mi(total_cases)
replace total_deaths = 0 if datestr == "30/01/2020" & mi(total_deaths)

replace total_cases = L.total_cases if mi(total_cases)
replace total_deaths = L.total_deaths if mi(total_deaths)

drop _fillin


/* issues:

- 20 observations missing date. dropping them.

*/

