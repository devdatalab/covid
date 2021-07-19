/***************************/
/* Clean UP Mortality data */
/***************************/

/* import raw data */
import excel "$covidpub/private/mortality/raw/UP RTI- Death Certificates Issued.xlsx", sheet("Year-wise original") cellrange(A9:P308) clear

/* preliminary cleaning */
replace B = B[_n-1] if mi(B)
drop A
drop if C == .
drop P

/* rename variabless */
ren B district
ren C year
ren D death_january
ren E death_february
ren F death_march
ren G death_april
ren H death_may
ren I death_june
ren J death_july
ren K death_august
ren L death_september
ren M death_october
ren N death_november 
ren O death_december

/* reshape from wide to long */
destring death_november, replace
reshape long death_, i(district year) j(month) string

/* generate state variable and clean further */
gen state = "Uttar Pradesh"
drop if death_ == .
ren death_ deaths

/* label and destring numeric vars */
la var state "State"
la var district "District"
la var month "Month"
la var year "Year"
la var deaths "Total Reported Deaths - CRS"

/* save clean data to scratch */
save $tmp/mort_up.dta, replace
