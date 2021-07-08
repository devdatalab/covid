/*****************************************/
/* Clean GHMC (Hyderabad) mortality data */
/*****************************************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/ghmc_certificates.xlsx", sheet("Sheet1") cellrange(A3:G14) clear

/* rename vars for reshape */
ren A month
ren B deaths2016
ren C deaths2017
ren D deaths2018
ren E deaths2019
ren F deaths2020
ren G deaths2021

/* convert months to lowercase for consistency */
replace month = lower(month)

/* reshape from wide to long */
reshape long deaths, i(month) j(year)

/* drop missing data */
drop if deaths == .

/* gen vars for state, district */
gen state = "Telangana"
gen district = "Hyderabad"

order state district deaths

/* save clean data to scratch */
save $tmp/mort_ghmc.dta, replace
