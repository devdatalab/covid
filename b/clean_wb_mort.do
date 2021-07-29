/************************************/
/* Clean West Bengal Mortality Data */
/************************************/

/* import raw data from statsofindia repo */
import delimited "https://raw.githubusercontent.com/statsofindia/india-mortality/master/district-level/West%20Bengal-districts.csv", clear

/* create variables for month and day of death */
gen year = substr(date, 1, 4)
gen month = substr(date, 6, 2)
gen day = substr(date, 9, 2)
destring year month day, replace

/* collapse on date of death, district and gender */
collapse (sum) deaths, by(district year month)

/* convert months from float to string for consistency */
str_month, float(month) string(str_month)

/* generate state var */
gen state = "West Bengal"

/* re-order variables */
order state district deaths year month 

save $tmp/mort_wb.dta, replace
