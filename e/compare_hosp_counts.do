use $hosp/ec_hospitals_dist, clear

/* merge to pop census vd/td dataset */
merge 1:1 pc11_state_id pc11_district_id using $hosp/pc_hospitals_dist
keep if _merge == 3

/* generate number of ec hospitals per 1000 people */
gen ec_gov_hosp_pc = ec_num_hosp_gov / pc11_pca_tot_p * 1000

/* generate hospital jobs per 1000 people */
gen ec_emp_gov_hosp_pc = ec_emp_hosp_gov / pc11_pca_tot_p * 1000

/* drop EC outliers */
replace ec_gov_hosp_pc = . if ec_gov_hosp_pc > .1
replace ec_emp_gov_hosp_pc = . if ec_emp_gov_hosp_pc > 3

/* drop PC outliers  */
replace pc_beds_all = . if pc_beds_all > 1.5


reg pc_beds_all ec_emp_gov_hosp_pc
scatter pc_beds_all ec_emp_gov_hosp_pc

gen tot_beds = ec_emp_hosp_gov + ec_emp_hosp_priv

scatter pc_beds_all tot_beds
graphout x


ren _merge _merge_ec_dlhs

/* get population (1:m since PC11 PCA is not clean / unique) */
merge 1:m pc11_state_id pc11_district_id using $pc11/pc11_pca_district_clean.dta, keepusing(pc11_pca_tot_p)

/* calculate  */

scatter ec_num_hosp_gov dlhs_num_hosp


scatter ec_num_hosp_gov dlhs_num_hosp
