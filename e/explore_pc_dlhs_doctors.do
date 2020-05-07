/* Investigates Hospital Definitions in DLHS4 and PC (Issue #14) */

/* open DLHS4 dataset */
use $covidpub/hospitals/dlhs4_hospitals_dist.dta, clear

/* merge with PC data */
merge 1:1 pc11_district_id using $covidpub/hospitals/pc_hospitals_dist.dta
drop if _merge != 3

/* collapse to state level */
collapse (sum) dlhs4* pc11_pca_tot_p pc_*, by(pc11_state_id)

/* add state names */
get_state_names, y(11)

/* drop states with populations less than 5m */
drop if pc11_pca_tot_p < 5000000

/* generate absolute values table */
sort pc_docs
list pc11_state_name pc_docs pc_docs_hosp dlhs4_total_staff

/* generate ratio variables */
gen docs_ratio = pc_docs / dlhs4_total_staff
gen docs_hosp_ratio = pc_docs_hosp / dlhs4_total_staff
gen ratio_diff = docs_hosp_ratio - docs_ratio

/* generate ratios table */
sort docs_ratio
list pc11_state_name docs_ratio docs_hosp_ratio ratio_diff
