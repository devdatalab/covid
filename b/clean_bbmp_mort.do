/*****************************************/
/* Clean BBMP (Bangalore) mortality data */
/*****************************************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/Karnataka, BBMP deaths data.xlsx", sheet("Sheet1") cellrange(A24:D37) clear

/* drop redundant obs and rename vars for reshape */
drop in 1
drop in 13
ren A month
ren B death_2019
ren C death_2020
ren D death_2021

/* reshape wide to long on monthly deaths */
reshape long death_, i(month) j(year)

/* ren deaths var and drop empty obs */
ren death deaths
drop if deaths == .

/* rename months for consistency */
replace month = "january" if month == "Jan"
replace month = "february" if month == "Feb"
replace month = "march" if month == "Mar"
replace month = "april" if month == "Apr"
replace month = "may" if month == "May"
replace month = "june" if month == "Jun"
replace month = "july" if month == "Jul"
replace month = "august" if month == "Aug"
replace month = "september" if month == "Sep"
replace month = "october" if month == "Oct"
replace month = "november" if month == "Nov"
replace month = "december" if month == "Dec"

/* gen vars for state, district */
gen state = "Karnataka"
gen district = "Bangalore (Urban)"

order state district deaths

/* save clean data to scratch */
save $tmp/mort_bbmp.dta, replace
