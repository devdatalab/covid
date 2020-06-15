/* use agricultural dataset */
use $covidpub/agmark/agmark_clean, clear

/* fix quantity data */
replace qty = . if unit == 1

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace

/* drop if missing state ID */
drop if mi(lgd_state_id)

/*******************************/
/* classify and encode regions */
/*******************************/

/* create empty regional variable */
gen str13  region = ""

/* code hilly states */
replace region = "hilly" if inlist(state, 1, 2, 3, 4, 5, 6)

/* code South states */
replace region = "south" if inlist(state, 27, 28, 29, 30, 32, 33)

/* code Northeast states */
replace region = "northeast" if inlist(state, 11, 12, 13, 14, 15, 16, 17, 18)

/* code northern states */
replace region = "north" if inlist(state, 7, 8, 9, 10, 19, 20, 21, 22, 23, 24)

/***************************/
/* normalize quantity data */
/***************************/

/* generate year and day variables  */
gen year = year(date)
gen doy = doy(date)
gen week = week(date)

/* generate mean price by item in 2018 */
egen mean_price_avg = mean(price_avg) if year == 2018, by(year item region)
egen qty_jan_1 = max(qty) if year == 2018 & doy == 1, by(year item region)
egen qty_normalizer = max(qty_jan_1), by(item region)

/* add that average to items from every year */
egen price_avg_2018 = max(mean_price_avg), by(item region)
drop mean_price_avg

/* normalize all volumes of items */
gen output = (qty * price_avg_2018)
drop if mi(output)
gen output_normalized = (output / qty_normalizer)

/* create "perishable good" dummy */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* collapse by normalized output */
collapse (sum) output_normalized output, by(perishable year week region)

/* save dataset, since we need to graph twice */
save $tmp/agmark_data, replace

/*****************************/
/* graph perishable goods */
/*****************************/

/* use temporary file dataset */
use $tmp/agmark_data, clear

/* drop nonperishable goods */
drop if perishable == 0

/* map distinct values to region variable */
egen group = group(region)

/* create r(max) which is the number of distinct values */
su group, meanonly

/* graph perishable good ouput by year, looping through regions */
forvalues i = 1/`r(max)' { 
  twoway (line output_normalized week if year == 2018 & group == `i') ///
   (line output_normalized week if year == 2019 & group == `i') ///
   (line output_normalized week if year == 2020 & group == `i'), ///
   title(`i') ///
   name(perish_`i', replace) ///
   legend(label(1 "2018") label(2 "2019") label(3 "2020")) xline(12)
}

/* combine perishable graphs */
graph combine perish_hilly perish_north perish_south perish_northeast, ///
ycommon r(1) name(regional_perish_combined, replace)

/* export graph */
graphout regional_perish_combined

/*****************************/
/* graph nonperishable goods */
/*****************************/

/* use temporary dataset */
use $tmp/agmark_data, clear

/* drop perishable goods */
drop if perishable = 1  
