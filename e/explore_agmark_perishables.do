use $covidpub/agmark/agmark_clean, clear
drop if mi(lgd_state_id)

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace
tostring lgd_district_id, format("%03.0f") replace

/* indicate if something is a perishable */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* generate year and day variables  */
gen year = year(date)
gen doy = doy(date)

/* generate mean price and quantity  in 2018 */
egen annual_price_avg = mean(price_avg), by(item year)
egen annual_qty_avg = mean(qty), by(item year)

/* collapse */
collapse annual_output_value, by(year doy lgd_state_id lgd_district_id)

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

twoway (line qty doy if year == 2018) (line qty doy if year == 2019) (line qty doy if year == 2020), title(perishables) name(perish, replace) legend(label(1 "2018", 2 "2019", 3 "2020")) xline(83)  legend(label(1 "2018") label(2 "2019") label(3 "2020"))

use $tmp/agmark_data, replace

replace qty = . if unit == 1

keep if perishable == 0

collapse (sum) qty, by(date lgd_state_id lgd_district_id)

merge m:1 date lgd_state_id lgd_district_id using $covidpub/covid/covid_infected_deaths
drop _merge

collapse (sum) qty total_cases total_deaths, by(date)

twoway (line qty doy if year == 2018) (line qty doy if year == 2019) (line qty doy if year ==2020), name(nonperish, replace) xline(83) title(non-perishables) legend(label(1 "2018") label(2 "2019") label(3 "2020"))
graphout perish
graphout nonperish

graph combine perish nonperish, ycommon r(1) name(combined, replace)
graphout combined



*********************************

use $tmp/agmark_data.dta, clear

replace qty = . if unit == 1

collapse (sum) qty (mean) price_avg, by(date item group)

gen daily_output_value = qty * price_avg

gen year = year(date)
gen week = week(date)

egen mean_qty = mean(qty) if year == 2018, by(year item)
egen mean_output_value = mean(daily_output_value) if year == 2018, by(year item)

collapse (sum) qty mean_qty mean_output_value, by (year week item group)

egen mean_output_value_2018 = max(mean_output_value), by(week item)
egen mean_qty_2018 = max(mean_qty), by(week item)


/* indicate if something is a perishable */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

save $tmp/perishables, replace
keep if perishable == 1
