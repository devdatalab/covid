/* combine DDL covid data and UChicago predictions */
use ~/iec/covid/forecasting/pred_data, clear

/* merge in district IDs */
gen pc11_district_name = lower(district)

/* fix_spelling to get district names harmonized with DDL PC11 key */
fix_spelling pc11_district_name, src($keys/pc11_district_key) group(pc11_state_id) replace

/* manual corrections from fix_spelling */
replace pc11_district_name = "kaimur" if pc11_district_name == "katihar"
replace pc11_district_name = "upper dibang valley" if district == "Upper Dibang Valley"
replace pc11_district_name = "aravalli" if pc11_district_name == "amreli"
replace pc11_district_name = "mahisagar" if pc11_district_name == "mahesana"
replace pc11_district_name = "vijayapura" if pc11_district_name == "bijapur"
replace pc11_district_name = "tenkasi" if pc11_district_name == "theni"
replace pc11_district_name = "tirupathur" if pc11_district_name == "tiruppur"

/* merge back to the key */
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

