/* create dataset with google serach data for covid symptoms */


/*  import csv file */
import delimited "$iec/covid/google/google_search_may2.csv", clear

/* merge state keys */
merge m:1 pc11_state_name using $pc11/pc11_pca_state_clean.dta

/* rename day variable in csv */
rename day date

/* modify date variable to create stata data */
gen year = 20
tostring year, generate(year2)
gen date2 = date+year2
drop date year year2
rename date2 date

/* gen stata date */
gen date2 = date(date, "DMY")
format date2 %d

/* rename date2 */
drop date
rename date2 date

/* keep relevant vars */
keep cough fever date pc11_state_id pc11_state_name pc11_pca_state_name

/* rename symptom variables */
rename cough cough_score
rename fever fever_score

/* drop missing values if any */
drop if fever_score==.

/* sort by state date */
sort pc11_state_id date

/* save as stata dataset */
save $iec/covid/google/google_top10_may.dta, replace
