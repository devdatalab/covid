/* combine results into a single export file, and impute some additional fields */

/* open hospital bed capacity */
use $covidpub/estimates/hospitals_dist, clear

/* merge with age distribution and infection fatality rate file */
merge 1:1 pc11_state_id pc11_district_id using $covidpub/estimates/district_age_dist_cfr, nogen

/* identify the districts that are least well prepared */
gen bottom_100_district_dlhs = rank_dlhs <= 100
gen bottom_100_district_pc = rank_pc <= 100
gen district_at_risk = bottom_100_district_pc == 1 & bottom_100_district_dlhs == 1

/* create scenarios where 1%, 5%, 10% of the district population gets infected */
gen predicted_mort_01 = pc11_pca_tot_t * 0.01 * district_estimated_cfr_t
gen predicted_hosp_01 = pc11_pca_tot_t * 0.01 * district_estimated_cfr_t * 5
gen predicted_mort_10 = pc11_pca_tot_t * 0.10 * district_estimated_cfr_t
gen predicted_hosp_10 = pc11_pca_tot_t * 0.10 * district_estimated_cfr_t * 5

/* calculate number of beds according to DLHS in each district */
gen dlhs_beds = dlhs_perk_pubpriv_beds / 1000 * pc11_pca_tot_t

/* calculate extent over capacity under 1% infection rate */
gen capacity_01 = predicted_hosp_01 / dlhs_beds
gen capacity_10 = predicted_hosp_10 / dlhs_beds

save $tmp/district_age_dist_cfr_hospitals, replace
export delimited $tmp/district_age_dist_cfr_hospitals, replace
