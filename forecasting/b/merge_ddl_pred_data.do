/* combine DDL covid data and UChicago predictions */
use ~/iec/covid/forecasting/pred_data, clear

/* merge in district IDs */
/* hack: keep only direct match */
gen pc11_district_name = lower(district)
merge m:1 pc11_state_id pc11_district_name using $keys/pc11_district_key
keep if _merge == 3
drop _merge

/* merge in DDL data */
merge m:1 pc11_state_id pc11_district_id using ~/iec/covid/forecasting/ddl_data
keep if _merge == 3
drop _merge

/* some var cleanup. start with formatting ids and geonames */
ren pc11_state_id pc11_s_id 
ren pc11_district_id pc11_d_id
ren pc11_state_name pc11_s_name
ren district pc11_d_name 
replace pc11_s_name = upper(substr(pc11_s_name,1,1)) + substr(pc11_s_name,2,.)

/* other var tweaks */
ren dates date
foreach var of varlist rt_* *cases* {
  replace `var' = round(`var', .01)
}

/* drop extraneous */
drop pc01* statename t_* pc11_district_name 

/* save to permadir */
save ~/iec/covid/forecasting/merged_data, replace
