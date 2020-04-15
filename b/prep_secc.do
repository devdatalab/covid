use ~/iec2/secc/final/collapse/village_consumption_imputed_pc11.dta, clear

keep pc11_state_id pc11_village_id secc_cons_per_cap

save $tmp/secc_cons_pc11, replace

/* get district identifiers */
merge 1:1 pc11_state_id pc11_village_id using $pc11/pc11r_pca_clean.dta, keepusing(pc11_district_id)

/* collapse to district level */
keep if _merge == 3
drop _merge

collapse (mean) secc_cons_per_cap, by(pc11_state_id pc11_district_id)

save $tmp/secc_cons_pc11_district, replace


use $hosp/hospitals_dist, clear

merge 1:1 pc11_state_id pc11_district_id using $tmp/secc_cons_pc11_district
keep if _merge == 3
drop _merge


sum pc_perk_beds_tot dlhs4_perk_total_beds
corr pc_perk_beds_tot ec_perk_emp_hosp_gov

corr pc_perk_beds_tot ec_perk_emp_hosp_tot

corr pc_perk_beds_tot secc_cons_per_cap
corr dlhs4_perk_total_beds secc_cons_per_cap
