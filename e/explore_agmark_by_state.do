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

/* drop observations without regions */
drop if mi(region)

/**************************************************/
/* generate output (avg price in 2018 * quantity) */
/**************************************************/

/* generate year and week variables  */
gen year = year(date)
gen week = week(date)

/* generate mean price by item in 2018 */
egen mean_price_avg = mean(price_avg) if year == 2018, by(year item region)

/* add that average to items from every year */
egen price_avg_2018 = max(mean_price_avg), by(item region)
drop mean_price_avg

/* normalize all volumes of items */
gen output = (qty * price_avg_2018)
drop if mi(output)

/* create "perishable good" dummy */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* collapse by output */
collapse (sum) output, by(perishable year week region)

/************************************************************/
/* normalize by dividing observations by weekly 2018 output */
/************************************************************/

/* add daily 2018 output from 2018 to each observation */
egen output_2018 = total(output) if year == 2018, by(week perishable region)
egen output_normalizer = max(output_2018), by(week perishable region)

/* normalize all weekly outputs */
gen normalized_output = (output / output_normalizer)

/* take log of normalized output */
gen log_normalized_output = ln(normalized_output)

/* save dataset, since we need to graph twice */
save $tmp/agmark_data, replace

/**************************/
/* graph perishable goods */
/**************************/

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
  twoway (line log_normalized_output week if year == 2019 & group == `i') ///
      (line log_normalized_output week if year == 2020 & group == `i'), ///
      title(`i') ///
      name(perish_`i', replace) ///
      legend(label(1 "2019") label(2 "2020")) xline(12)
}

graph rename perish_1 perish_hilly, replace
graph rename perish_2 perish_north, replace
graph rename perish_3 perish_northeast, replace
graph rename perish_4 perish_south, replace

/* combine perishable graphs */
graph combine perish_hilly perish_north perish_south perish_northeast, ///
    ycommon r(1) name(regional_perish_combined, replace) ///
    note("1: Hilly, 2: North, 3: Northeast, 4: South") ///
    title(perishables)
    
/* export graph */
graphout regional_perish_combined

/*****************************/
/* graph nonperishable goods */
/*****************************/

/* use temporary dataset */
use $tmp/agmark_data, clear

/* drop perishable goods */
drop if perishable == 1  

/* map distinct values to region variable */
egen group = group(region)

/* create r(max) which is the number of distinct values */
su group, meanonly

/* graph perishable good ouput by year, looping through regions */
forvalues i = 1/`r(max)' {
  twoway (line log_normalized_output week if year == 2019 & group == `i') ///
      (line log_normalized_output week if year == 2020 & group == `i'), ///
      title(`i') ///
      name(nonperish_`i', replace) ///
      legend(label(1 "2019") label(2 "2020")) xline(12)
}

graph rename nonperish_1 nonperish_hilly, replace
graph rename nonperish_2 nonperish_north, replace
graph rename nonperish_3 nonperish_northeast, replace
graph rename nonperish_4 nonperish_south, replace

/* combine perishable graphs */
graph combine nonperish_hilly nonperish_north nonperish_south nonperish_northeast, ///
    ycommon r(1) name(regional_nonperish_combined, replace) ///
    note("1: Hilly, 2: North, 3: Northeast, 4: South") ///
    title(nonperishables)
    
/* export graph */
graphout regional_nonperish_combined
