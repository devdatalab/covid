/***************************************************************/
/* Clean Kolkata Municipal Corporation Death Registration data */
/***************************************************************/

/* read in raw csv data (source: https://github.com/thejeshgn/KMCDeathRecords) */
import delimited "$covidpub/mortality/raw/death_records_kolkata.csv", clear

/* drop empty variables */
drop dateofregistration deathdate crematoriumcode regnno recordssourcerawdatafile

/* rename and label variables */
ren deceasedname deceased_name
ren yearofregistration year
ren deathregnno death_reg_no
ren crematoriumname crematorium
ren deceasedsex sex
ren fathername father_name
ren deathsite death_site
ren recordssource record_source
ren recordscity city
ren recordsdateofdeath death_date

la var deceased_name "Name of Deceased"
la var year "Year of Death"
la var death_reg_no "Death Registration Number"
la var crematorium "Crematorium"
la var sex "Sex of Deceased"
la var father_name "Father Name"
la var death_site "Site of Death"
la var record_source "Source"
la var city "City"
la var death_date "Date of Death"

/* gender for some obs is unidentified for various reasons and is missing - label them as unknown */
replace sex = "UNKNOWN" if sex == " "

/* create placeholder variable for collapse */
gen death = 1

/* collapse on date of death, city and gender */
collapse (sum) death, by(city death_date sex)

/* reshape to wide - gender disaggregation in separate variables */
reshape wide death city, i(death_date) j(sex) string

/* create variables for year, month and day of death */
gen year = substr(death_date, 1, 4)
gen month = substr(death_date, 6, 2)
gen date = substr(death_date, 9, 2)
destring year month date, replace

/* clean up further - drop redundant variables, rename and label */
drop cityFEMALE cityUNKNOWN
ren cityMALE city
ren deathFEMALE death_female
ren deathMALE death_male
ren deathUNKNOWN death_other

la var city "City"
la var death_female "Total Deaths: Female"
la var death_male "Total Deaths: Male"
la var death_other "Total Deaths: Other"

/* compute total deaths by summing gender-wise deaths */
egen death_total = rowtotal(death_male death_female death_other)
la var death_total "Total Deaths"

/* re-order variables */
order city death_date year month date

save $covidpub/mortality/kolkata_deaths, replace
