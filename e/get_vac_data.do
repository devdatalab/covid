/* define lgd matching programs */
qui do $ddl/covid/covid_progs.do
qui do $ddl/tools/do/tools.do

/* Pull district-level vaccination data from covid19india API */
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

save $tmp/vaccines_clean , replace

/****************/
/* match to LGD */
/****************/
use $tmp/vaccines_clean, clear

/* drop extra variables */
drop district_key state_code

/* create lgd_state variable to merge */
gen lgd_state_name = lower(state)

/* fix dadra and nager haveli and daman and diu */
replace lgd_state_name = "dadra and nagar haveli" if district == "Dadra and Nagar Haveli"
replace lgd_state_name = "daman and diu" if (district == "Daman") | (district == "Diu")

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_state_key, keepusing(lgd_state_id) keep(match master) nogen

/* now create an lgd_district variable to merge */
gen lgd_district_name = lower(district)

/* fix misspellings and name changes */
synonym_fix lgd_district_name, synfile($ddl/covid/b/str/cov19india_vaccine_district_fixes.txt) replace

/* save */
save $tmp/temp, replace

/* run masala merge */
keep lgd_state_name lgd_district_name
duplicates drop
masala_merge lgd_state_name using $keys/lgd_district_key, s1(lgd_district_name) minbigram(0.2) minscore(0.6) outfile($tmp/vaccine_lgd_district)

/* keep master matches */
keep if match_source < 7

/* drop unneeded variables */
keep lgd_state_name lgd_district_name_using lgd_district_name_master

/* merge data back in */
ren lgd_district_name_master lgd_district_name
merge 1:m lgd_state_name lgd_district_name using $tmp/temp
drop _merge

/* now replace the district name with the lgd key name */
drop lgd_district_name
ren lgd_district_name_using lgd_district_name

/* ensure that it is it square */
egen dgroup = group(lgd_state_name lgd_district_name)
fillin date dgroup
drop dgroup _fillin

/* save data */
export delimited using "$tmp/covid_vaccination.csv", replace
