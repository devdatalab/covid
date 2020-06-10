use $covidpub/agmark/agmark_clean, clear
drop if mi(lgd_state_id)

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace
tostring lgd_district_id, format("%03.0f") replace

/* indicate if something is a perishabel */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* save overall data file */
save $tmp/agmark_data, replace

/**********************/
/* Explore new trends */
/**********************/

use $tmp/agmark_data, replace

replace qty = . if unit == 1

keep if perishable == 1

collapse (sum) qty, by(date lgd_state_id lgd_district_id)

merge m:1 date lgd_state_id lgd_district_id using $covidpub/covid/covid_infected_deaths
drop _merge

collapse (sum) qty total_cases total_deaths, by(date)

gen year = year(date)

gen doy = doy(date)

twoway (line qty doy if year == 2018) (line qty doy if year == 2019) (line qty doy if year == 2020), title(perishables) name(perish, replace) legend(label(1 "2018", 2 "2019", 3 "2020")) xline(83)  legend(label(1 "2018") label(2 "2019") label(3 "2020"))

use $tmp/agmark_data, replace

replace qty = . if unit == 1

keep if perishable == 0

collapse (sum) qty, by(date lgd_state_id lgd_district_id)

merge m:1 date lgd_state_id lgd_district_id using $covidpub/covid/covid_infected_deaths
drop _merge

collapse (sum) qty total_cases total_deaths, by(date)

gen year = year(date)

gen doy = doy(date)

twoway (line qty doy if year == 2018) (line qty doy if year == 2019) (line qty doy if year ==2020), name(nonperish, replace) xline(83) title(non-perishables) legend(label(1 "2018") label(2 "2019") label(3 "2020"))
graphout perish
graphout nonperish

graph combine perish nonperish, ycommon r(1) name(combined, replace)
graphout combined
