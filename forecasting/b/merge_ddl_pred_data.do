/****************************/
/* District level data join */
/****************************/

/* pull globals */
process_yaml_config ~/ddl/covid/forecasting/config/config.yaml

/* combine DDL covid data and UChicago predictions */
use $cdata/pred_data_district, clear

/* merge in DDL data */
merge m:1 lgd_state_id lgd_district_id using $cdata/ddl_data
keep if _merge == 3
drop _merge

/* some var cleanup. start with formatting ids and geonames */
ren lgd_state_id lgd_s_id 
ren lgd_district_id lgd_d_id
ren lgd_state_name lgd_s_name
ren lgd_district_name lgd_d_name 

/* capitalize geonames */
replace lgd_s_name = upper(substr(lgd_s_name,1,1)) + substr(lgd_s_name,2,.)
replace lgd_d_name = upper(substr(lgd_d_name,1,1)) + substr(lgd_d_name,2,.)

/* other var tweaks */
ren dates date
foreach var of varlist rt_* *cases* {
  replace `var' = round(`var', .01)
}

/* confirm drop of extraneous modeling vars */
cap drop t_*

/* save to permadir */
save $cdata/merged_data_district, replace

/* CSV version */
outsheet using $cdata/merged_data_district.csv, comma replace
