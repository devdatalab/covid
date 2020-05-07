/* generates clean district key out of pdf-to-csv conversion of Appendix-I */

/* define lgd matching program */
qui do $ddl/tools/do/lgd_district_match.do

/* load data */
insheet using ~/iec1/nss/nss-75-health/Appendix-I.csv, clear

/* drop unnecessary vars */
drop v1 v3 v6 v11 v10

/* fix states */
/* note: uses lgd id's so just need to get state names right */

/* clean up state name variable */
gen lgd_state_name = v9
replace lgd_state_name = "" if real(lgd_state_name) ~= .
replace lgd_state_name = substr(lgd_state_name, 1, strpos(lgd_state_name, "(") - 1) if regexm(lgd_state_name, "\(")
replace lgd_state_name = lower(trim(lgd_state_name))
replace lgd_state_name = subinstr(lgd_state_name, "&", "and", .)
replace lgd_state_name = "jammu and kashmir" if inlist(lgd_state_name, "jammu", "kashmir")
replace lgd_state_name = "dadra and nagar haveli" if lgd_state_name == "d and n haveli"
replace lgd_state_name = "andaman and nicobar islands" if lgd_state_name == "a"
drop if inlist(lgd_state_name, "code", "state/u.t.")

/* generate district vars */
gen lgd_district_name = lower(trim(v7))
gen nss_district_id = v8

/* drop bad obs */
drop if real(nss_district_id) == . | real(nss_district_id) < 0

/* fill in state vars */
replace lgd_state_name = lgd_state_name[_n-1] if mi(lgd_state_name)

/* generate nss district name variable to run lgd district matching program */
gen nss_district_name = lgd_district_name
drop lgd_district_name

/* note: district formatting must be done before lgd state match */
/* or else ladakh UT will not match at the state merging step */
lgd_dist_format nss_district_name

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_pc11_state_key, keepusing(lgd_state_id)
drop if _merge == 2
drop _merge
/* note: key missing arunachal and mizoram */

/* run lgd district matching program */
lgd_dist_match nss_district_name

/* generate nss state id (same as lgd id) */
gen nss_state_id = lgd_state_id

/* there were 648 obs in the dataset */
/* two were duplicate obs for aligarh and sant kabeer nagar in UP */
/* one did not match - jaintia hills (this district is outdated) */
/* it was split into east and west jaintia hills in 2012 */
/* unclear which of these two we should merge jaintia hills to */
/* the final key has 645 obs */

/* save */
save $iec1/nss/nss-75-health/nss75_lgd_district_key, replace
