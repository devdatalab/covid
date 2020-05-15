/**************************************/
/* prepare bihar hospitalization data */
/**************************************/

/* import and lcase raw data */
import excel $health/bihar/raw/bihar_ventilators_beds_v2.xlsx, clear sheet("Data - Public Hospitals - Bihar") firstrow
ren *, lower

/* clean district name */
replace district = lower(district)
ren district lgd_district_name
gen lgd_state_name = "bihar"
drop if lgd_district_name == "bihar"

/* run standard district name fixes */
synonym_fix lgd_district_name, synfile(~/ddl/covid/b/str/lgd_district_fixes.txt) replace group(lgd_state_name)

/* merge to the district key to get standardized ids */
merge 1:1 lgd_state_name lgd_district_name using $keys/lgd_district_key, assert(using match) keepusing(lgd_state_id lgd_district_id)
keep if lgd_state_name == "bihar"
assert _merge == 3
drop _merge

/* save clean bihar hospital data */
drop srno
order lgd_state_id lgd_district_id lgd_state_name lgd_district_name 
save $health/bihar/bihar_moh_hospitals, replace


/***************************/
/* prepare bihar case data */
/***************************/
/* open and lowercase raw data */
import excel $health/bihar/raw/bihar_case_data_may11.xlsx, clear firstrow
ren *, lower
drop sno

/* rename vars */
ren causeofsample contacttrace1
ren h contacttrace2

/* clean district name */
replace district = lower(district)
ren district lgd_district_name
gen lgd_state_name = "bihar"

/* run standard district name fixes */
synonym_fix lgd_district_name, synfile(~/ddl/covid/b/str/lgd_district_fixes.txt) replace group(lgd_state_name)

/* merge to the district key to get standardized ids */
/* note we keep using-only districts --- they have no cases yet  */
merge m:1 lgd_state_name lgd_district_name using $keys/lgd_district_key, keepusing(lgd_state_id lgd_district_id)
keep if lgd_state_name == "bihar"
review_merge lgd_district_name
assert _merge != 1
drop _merge

/* save clean bihar case data */
order lgd_state_id lgd_district_id lgd_state_name lgd_district_name 
save $health/bihar/bihar_moh_cases, replace

