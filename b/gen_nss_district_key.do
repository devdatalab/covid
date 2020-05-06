/* generates clean district key out of pdf-to-csv conversion of Appendix-I */

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

/* merge in lgd state id */
merge m:1 lgd_state_name using $keys/lgd_pc11_state_key, keepusing(lgd_state_id)
drop if _merge == 2
drop _merge
/* note: key missing arunachal and mizoram */

/* manually clean district names */

/* merge in district id's */
merge 1:1 lgd_state_name lgd_district_name using $keys/lgd_pc11_district_key
drop if _merge == 2
drop _merge

/* generate nss state id (same as lgd id) */
gen nss_state_id = lgd_state_id

/* save */
save $iec1/nss/nss-75-health/nss75_lgd_district_key, replace
