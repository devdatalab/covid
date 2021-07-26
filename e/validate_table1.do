/* load state mortality data */
use "$covidpub/mortality/state_mort_month.dta", replace

/******************/
/* States: Wave 1 */
/******************/

keep if inlist(lgd_state_name, "madhya pradesh", "kerala", "assam", ///
    "haryana", "andhra pradesh", "tamil nadu")

/* keep relevant time periods */
drop if year < 2018

/* generate period */
gen period = 1 if lgd_state_name == "madhya pradesh" & inrange(month, 7, 12) ///
    & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "kerala" & inrange(month, 8, 12) & year == 2019
replace period = 1 if lgd_state_name == "kerala" & inrange(month, 1, 3) & year == 2020
replace period = 1 if lgd_state_name == "assam" & inrange(month, 7, 10) & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "andhra pradesh" & inrange(month, 7, 10) & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "haryana" & inrange(month, 7, 12) & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "tamil nadu" & inrange(month, 6, 11) & inlist(year, 2018, 2019)

replace period = 2 if lgd_state_name == "madhya pradesh" & inrange(month, 7, 12) ///
    & year == 2020
replace period = 2 if lgd_state_name == "kerala" & inrange(month, 8, 12) & year == 2020
replace period = 2 if lgd_state_name == "kerala" & inrange(month, 1, 3) & year == 2021
replace period = 2 if lgd_state_name == "assam" & inrange(month, 7, 10) & inlist(year, 2020)
replace period = 2 if lgd_state_name == "andhra pradesh" & inrange(month, 7, 10) & inlist(year, 2020)
replace period = 2 if lgd_state_name == "haryana" & inrange(month, 7, 12) & inlist(year, 2020)
replace period = 2 if lgd_state_name == "tamil nadu" & inrange(month, 6, 11) & inlist(year, 2020)

/* drop data for months outside the frame */
drop if period == .

/* modify year for kerala for collapse */
replace year = 2020 if period == 1 & lgd_state_name == "kerala"
replace year = 2021 if period == 2 & lgd_state_name == "kerala"

/* collapse deaths by period */
collapse (sum) deaths, by(lgd_state_name period year)

/* generate deaths per 1000 */
gen deaths_perk = deaths/1000

/* list */
list lgd_state_name year deaths_perk

/* table 1 shows one number for pre pandemic era presumably avg */
collapse (mean) deaths_perk, by(lgd_state_name period)
la define p 1 "pre-pandemic" 2 "pandemic"
la val period p
list lgd_state_name period deaths_perk

/*******************/
/* States - Wave 2 */
/*******************/

/* load state mortality data */
use "$covidpub/mortality/state_mort_month.dta", replace

keep if inlist(lgd_state_name, "madhya pradesh", "kerala", ///
    "haryana", "andhra pradesh", "tamil nadu")

/* generate period */
gen period = 1 if lgd_state_name == "madhya pradesh" & inrange(month, 3, 5) ///
    & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "kerala" & inrange(month, 4, 5) & year == 2019
replace period = 1 if lgd_state_name == "andhra pradesh" & inrange(month, 4, 6) & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "haryana" & inrange(month, 4, 5) & inlist(year, 2018, 2019)
replace period = 1 if lgd_state_name == "tamil nadu" & inrange(month, 3, 5) & inlist(year, 2018, 2019)

replace period = 2 if lgd_state_name == "madhya pradesh" & inrange(month, 3, 5) ///
    & inlist(year, 2021)
replace period = 2 if lgd_state_name == "kerala" & inrange(month, 4, 5) & year == 2021
replace period = 2 if lgd_state_name == "andhra pradesh" & inrange(month, 4, 6) & inlist(year, 2021)
replace period = 2 if lgd_state_name == "haryana" & inrange(month, 4, 5) & inlist(year, 2021)
replace period = 2 if lgd_state_name == "tamil nadu" & inrange(month, 3, 5) & inlist(year, 2021)

/* drop data for months outside the frame */
drop if period == .

/* collapse deaths by period */
collapse (sum) deaths, by(lgd_state_name period year)

/* generate deaths per 1000 */
gen deaths_perk = deaths/1000

/* list */
list lgd_state_name year deaths_perk

/* table 1 shows one number for pre pandemic era presumably avg */
collapse (mean) deaths_perk, by(lgd_state_name period)
la val period p
list lgd_state_name period deaths_perk

/*******************/
/* Cities - Wave 1 */
/*******************/

/* load district mortality data */
use "$covidpub/mortality/district_mort_month.dta", replace

/* keep relevant locations */
keep if inlist(lgd_district_name , "hyderabad", "bengaluru urban", ///
    "kolkata", "chennai")

/* generate periods */
gen period = 1 if lgd_district_name == "hyderabad" & inrange(month, 6, 12) & inlist(year, 2016, 2019)
replace period = 1 if lgd_district_name == "bengaluru urban" & inrange(month, 7, 12) & inlist(year, 2019)
replace period = 1 if lgd_district_name == "chennai" & inrange(month, 6, 12) & inlist(year, 2015, 2019)
replace period = 1 if lgd_district_name == "kolkata" & inrange(month, 7, 12) & inlist(year, 2015, 2019)

replace period = 2 if lgd_district_name == "hyderabad" & inrange(month, 6, 12) & inlist(year, 2020)
replace period = 2 if lgd_district_name == "bengaluru urban" & inrange(month, 7, 12) & inlist(year, 2020)
replace period = 2 if lgd_district_name == "chennai" & inrange(month, 6, 12) & inlist(year, 2020)
replace period = 2 if lgd_district_name == "kolkata" & inrange(month, 7, 12) & inlist(year, 2020)

/* drop data for months outside the frame */
drop if period == .

/* collapse deaths by period */
collapse (sum) deaths, by(lgd_district_name period year)

/* generate deaths per 1000 */
gen deaths_perk = deaths/1000

/* list */
list lgd_district_name year deaths_perk

/* table 1 shows one number for pre pandemic era presumably avg */
collapse (mean) deaths_perk, by(lgd_district_name period)
la val period p
list lgd_district_name period deaths_perk

/*******************/
/* Cities - Wave 2 */
/*******************/

/* load district mortality data */
use "$covidpub/mortality/district_mort_month.dta", replace

/* keep relevant locations */
keep if inlist(lgd_district_name , "hyderabad", "bengaluru urban", ///
    "kolkata", "chennai")

/* generate periods */
gen period = 1 if lgd_district_name == "hyderabad" & inrange(month, 4, 5) & inlist(year, 2016, 2019)
replace period = 1 if lgd_district_name == "bengaluru urban" & inrange(month, 4, 5) & inlist(year, 2019)
replace period = 1 if lgd_district_name == "chennai" & inrange(month, 3, 4) & inlist(year, 2018, 2019)
replace period = 1 if lgd_district_name == "kolkata" & inrange(month, 3, 4) & inlist(year, 2018, 2019)

replace period = 2 if lgd_district_name == "hyderabad" & inrange(month, 4, 5) & inlist(year, 2021)
replace period = 2 if lgd_district_name == "bengaluru urban" & inrange(month, 4, 5) & inlist(year, 2021)
replace period = 2 if lgd_district_name == "chennai" & inrange(month, 3, 4) & inlist(year, 2021)
replace period = 2 if lgd_district_name == "kolkata" & inrange(month, 3, 4) & inlist(year, 2021)

/* drop data for months outside the frame */
drop if period == .

/* collapse deaths by period */
collapse (sum) deaths, by(lgd_district_name period year)

/* generate deaths per 1000 */
gen deaths_perk = deaths/1000

/* list */
list lgd_district_name year deaths_perk

/* table 1 shows one number for pre pandemic era presumably avg */
collapse (mean) deaths_perk, by(lgd_district_name period)
la val period p
list lgd_district_name period deaths_perk
