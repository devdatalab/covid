**********************************************************
* Convert all volumes to outputs (avg price * quantity)  *
**********************************************************

/* use agricultural dataset */
use $covidpub/agmark/agmark_clean, clear

/* fix quantity data */
replace qty = . if unit == 1

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace
tostring lgd_district_id, format("%03.0f") replace

/* generate year and day variables  */
gen year = year(date)
gen doy = doy(date)
gen week = week(date)

/* generate mean price by item in 2018 */
egen mean_price_avg = mean(price_avg) if year == 2018, by(year item)
egen qty_jan_1 = qty if year == 2018 & doy == 1, by(year item)
egen qty_normalizer = max(qty_jan_1), by(item)

/* add that average to items from every year */
egen price_avg_2018 = max(mean_price_avg), by(item)
drop mean_price_avg

/* normalize all volumes of items */
gen output = (qty * price_avg_2018)
drop if mi(output)

gen output_normalized = output/qty_normalizer

/* create "perishable good" dummy */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* collapse by normalized output */
collapse (sum) output_normalized output, by(perishable year week)

/* save dataset, since we need to graph twice */
save $tmp/agmark_data, replace

/* drop nonperishable goods */
drop if perishable == 0

/* graph perishable good ouput by year */
twoway (line output week if year == 2018) ///
    (line output  week if year == 2019) ///
    (line output week if year == 2020), ///
    title(perishables) ///
    name(perish, replace) ///
    legend(label(1 "2018") label(2 "2019") label(3 "2020")) xline(12)
/* open temporary dataset again to graph nonperishables */
use $tmp/agmark_data, clear

/* drop perishable goods */
drop if perishable == 1

/* graph nonperishable good output by year */
twoway (line output week if year == 2018) ///
    (line output  week if year == 2019) ///
    (line output week if year == 2020), ///
    title(non-perishables) ///
    name(nonperish, replace) ///
    legend(label(1 "2018") label(2 "2019") label(3 "2020")) xline(12)

/* export graphs */
graphout perish
graphout nonperish

/* combine graphs */
graph combine perish nonperish, ycommon r(1) name(combined, replace)
graphout combined

/************************************************************/
/* Same as last, but normalizing Jan. 1, 2018 to output = 1 */
/************************************************************/

/* use agricultural dataset */
use $covidpub/agmark/agmark_clean, clear

/* fix quantity data */
replace qty = . if unit == 1

/* adjust formats of identifying variables */
format date %dM_d,_CY
tostring lgd_state_id, format("%02.0f") replace
tostring lgd_district_id, format("%03.0f") replace

/* generate year and day variables  */
gen year = year(date)
gen doy = doy(date)
gen week = week(date)

/* generate mean price by item in 2018 */
egen mean_price_avg = mean(price_avg) if year == 2018, by(year item)
egen qty_jan_1 = max(qty) if year == 2018 & doy == 1, by(year item)
egen qty_normalizer = max(qty_jan_1), by(item)

/* add that average to items from every year */
egen price_avg_2018 = max(mean_price_avg), by(item)
drop mean_price_avg

/* normalize all volumes of items */
gen output = (qty * price_avg_2018)
drop if mi(output)

gen output_normalized = output/qty_normalizer

/* create "perishable good" dummy */
gen perishable = 1 if (group == 8 | group == 9 | group == 15)
replace perishable = 0 if mi(perishable)

/* collapse by normalized output */
collapse (sum) output_normalized output, by(perishable year week)

/* save dataset, since we need to graph twice */
save $tmp/agmark_data, replace

/* drop nonperishable goods */
drop if perishable == 0

/* graph perishable good ouput by year */
twoway (line output_normalized week if year == 2018) ///
    (line output_normalized  week if year == 2019) ///
    (line output_normalized week if year == 2020), ///
    title(perishables) ///
    name(perish_normalized, replace) ///
    legend(label(1 "2018") label(2 "2019") label(3 "2020")) xline(12)
/* open temporary dataset again to graph nonperishables */
use $tmp/agmark_data, clear

/* drop perishable goods */
drop if perishable == 1

/* graph nonperishable good output by year */
twoway (line output_normalized week if year == 2018) ///
    (line output_normalized  week if year == 2019) ///
    (line output_normalized week if year == 2020), ///
    title(non-perishables) ///
    name(nonperish_normalized, replace) ///
    legend(label(1 "2018") label(2 "2019") label(3 "2020")) xline(12)

graph combine nonperish_normalized perish_normalized, ycommon r(1) name(combined_normalized, replace)
graphout combined_normalized
