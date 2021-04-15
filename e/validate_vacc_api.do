/* Clean, process and validate district-level vaccination data from covid19india */

/* Import district-level vaccination data from covid19india API */
import delimited "https://api.covid19india.org/csv/latest/cowin_vaccine_data_districtwise.csv", clear

/* rename all the variables */
local k = 7 
local j = 1 

foreach var of var v* {

local label : variable label `var'
local label: subinstr local label "/" ""
local label: subinstr local label "/" ""
local label: subinstr local label "." "_"

ren v`k' v_`label'_`j'
local k = `k'+1
local j = `j'+1 

cap ren v_`label'_* v_`label'_(#), renumber

}

/* drop first row containing variable names in the raw API */
drop in 1

/* tag duplicates */
duplicates tag state_code district_key, gen(tag)
keep if tag == 0
drop tag
cap drop v__*

/* more renaming */
forval i = 1/10 {
  ren v*`i' v`i'*
}

ren v*_ v*

/* reshape data from wide to long */
reshape long v1_ v2_ v3_ v4_ v5_ v6_ v7_ v8_ v9_ v10_, i(state district state_code district_key cowinkey) j(date) string

destring v*, replace

/* label variables */
la var v1_ "Total Individuals Registered"	
la var v2_ "Total Sessions Conducted"	
la var v3_ "Total Sites" 	
la var v4_ "First Dose Administered"	
la var v5_ "Second Dose Administered"	
la var v6_ "Male(Individuals Vaccinated)"	
la var v7_ "Female(Individuals Vaccinated)"	
la var v8_ "Transgender(Individuals Vaccinated)"	
la var v9_ "Total Covaxin Administered"	
la var v10_ "Total CoviShield Administered"

/* rename final vars */
ren v1_ total_reg
ren v2_ total_sessions
ren v3_ total_sites
ren v4_ total_first_dose
ren v5_ total_second_dose
ren v6_ total_vac_male
ren v7_ total_vac_female
ren v8_ total_vac_trans
ren v9_ total_covaxin
ren v10_ total_covishield

/* create time variable */
gen day = substr(date, 1, 2)
gen month = substr(date, 3, 2)
gen year = substr(date, 5, 4)

destring day month year, replace
gen edate = mdy(month, day, year)
format edate %dM_d,_CY

/* generate unique id on district key and date */
egen id = group(district_key edate)
isid id

/* set as panel */
xtset id edate, daily

/* calculate daily counts */

/* covishield */
bys district_key: gen daily_covishield = total_covishield- total_covishield[_n-1]
replace daily_covishield = total_covishield if daily_covishield == .

/* covaxin */
bys district_key: gen daily_covaxin = total_covaxin - total_covaxin[_n-1]
replace daily_covaxin = total_covaxin if daily_covaxin == .

/* daily vaccinations - male */
bys district_key: gen daily_vac_male = total_vac_male - total_vac_male[_n-1]
replace daily_vac_male = total_vac_male if daily_vac_male == .

/* daily vaccinations - female */
bys district_key: gen daily_vac_female = total_vac_female - total_vac_female[_n-1]
replace daily_vac_female = total_vac_female if daily_vac_female == .

/* first dose */
bys district_key: gen daily_first_dose = total_first_dose - total_first_dose[_n-1]
replace daily_first_dose = total_first_dose if daily_first_dose == .

/* second dose */
bys district_key: gen daily_second_dose = total_second_dose - total_second_dose[_n-1]
replace daily_second_dose = total_second_dose if daily_second_dose == .

/* daily registrations */
bys district_key: gen daily_reg = total_reg - total_reg[_n-1]
replace daily_reg = total_reg if daily_reg == .

/* daily sessions */
bys district_key: gen daily_sessions = total_sessions - total_sessions[_n-1]
replace daily_sessions = total_sessions if daily_sessions == .

/* daily sites */
bys district_key: gen daily_sites = total_sites - total_sites[_n-1]
replace daily_sites = total_sites if daily_sites == .

***************************************************

* drop today's observations since updated data will reflect tomorrow
 
drop if edate == 22384

/* Data validation checks - 15/04/2021 */ 

* 1. Daily and total covishield - 

* 514 obs have < 0 values for daily count

tab state if daily_covishield < 0
tab edate if daily_covishield < 0

* 2. Daily and total covaxin 

* 355 observations have < 0 values for daily count
 
sum daily_covaxin if daily_covaxin < 0
tab edate if daily_covaxin < 0

* 3. Daily vaccinations - male

* 615 obs have < 0 values for daily count

sum daily_vac_male if daily_vac_male < 0
tab edate if daily_vac_male < 0

/* to make the visualizations, drop all the < 0 obs 

foreach i of var daily_* {

drop if `i' < 0

}

*/

collapse (sum) daily_covishield daily_covaxin daily_vac_male daily_vac_female daily_first_dose daily_second_dose daily_reg daily_sessions daily_sites, by(edate)

ren daily_* *

foreach i of var * {

gen total_`i' = sum(`i')

}
