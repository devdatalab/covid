/********************************/
/* Clean Chennai mortality data */
/********************************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/chennai.xlsx", sheet("Sheet2") cellrange(A1:M13) clear firstrow

/* rename vars for reshape */
ren Month month
ren B deaths2010
ren C deaths2011
ren D deaths2012
ren E deaths2013
ren F deaths2014
ren G deaths2015
ren H deaths2016
ren I deaths2017
ren J deaths2018
ren K deaths2019
ren L deaths2020
ren M deaths2021

/* convert months to lowercase for consistency */
replace month = lower(month)

/* reshape from wide to long */
reshape long deaths, i(month) j(year)

/* drop missing obs */
drop if deaths == .

/* generate vars for state, district */
gen state = "Tamil Nadu"
gen district = "Chennai"

order state district deaths

/* save clean data to scratch */
save $tmp/mort_chennai, replace
