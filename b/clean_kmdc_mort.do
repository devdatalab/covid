/***************************************************************/
/* Clean Kolkata Municipal Corporation Death Registration data */
/***************************************************************/

/* read in raw csv data (source: https://github.com/thejeshgn/KMCDeathRecords) */
import delimited "$covidpub/private/mortality/raw/death_records_kolkata.csv", clear

/* drop empty variables */
drop dateofregistration deathdate crematoriumcode regnno recordssourcerawdatafile yearofregistration

/* rename and label variables */
ren deceasedname deceased_name
ren deathregnno death_reg_no
ren crematoriumname crematorium
ren deceasedsex sex
ren fathername father_name
ren deathsite death_site
ren recordssource record_source
ren recordscity district
ren recordsdateofdeath death_date

la var deceased_name "Name of Deceased"
la var death_reg_no "Death Registration Number"
la var crematorium "Crematorium"
la var sex "Sex of Deceased"
la var father_name "Father Name"
la var death_site "Site of Death"
la var record_source "Source"
la var district "District"
la var death_date "Date of Death"

/* gender for some obs is unidentified for various reasons and is missing - label them as unknown */
replace sex = "UNKNOWN" if sex == " "

/* create placeholder variable for collapse */
gen deaths = 1

/* create variables for month and day of death */
gen year = substr(death_date, 1, 4)
gen month = substr(death_date, 6, 2)
gen date = substr(death_date, 9, 2)
destring year month date, replace

/* collapse on date of death, district and gender */
collapse (sum) deaths, by(district year month)

/* convert months from float to string for consistency */
str_month, float(month) string(str_month)

/* generate state var */
gen state = "West Bengal"

/* re-order variables */
order state district deaths year month 

save $tmp/mort_kolkata.dta, replace
