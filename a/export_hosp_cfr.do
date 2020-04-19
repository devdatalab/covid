/* open hospital bed capacity */
use $covidpub/hospitals_dist_export.dta, clear

/* calculate the districts that are least well prepared */
gen bottom_100_district_dlhs4 = rank_dlhs4 <= 100
gen bottom_100_district_pc = rank_pc <= 100
gen district_at_risk = bottom_100_district_pc == 1 & bottom_100_district_dlhs4 == 1

/* merge with age distribution and infection fatality rate file */
merge 1:1 pc11_state_id pc11_district_id using $covidpub/district_age_dist_cfr, nogen

save $covidpub/out/district_age_dist_cfr_hospitals, replace

/* create scenarios where 1%, 5%, 10% of the district population gets infected */
gen predicted_mort_01 = pc11_pca_tot_t * 0.01 * district_estimated_cfr_t
gen predicted_hosp_01 = pc11_pca_tot_t * 0.01 * district_estimated_cfr_t * 5
gen predicted_mort_10 = pc11_pca_tot_t * 0.10 * district_estimated_cfr_t
gen predicted_hosp_10 = pc11_pca_tot_t * 0.10 * district_estimated_cfr_t * 5

/* calculate number of beds according to DLHS in each district */
gen dlhs_beds = dlhs4_perk_beds_pubpriv / 1000 * pc11_pca_tot_t

/* calculate extent over capacity under 1% infection rate */
gen capacity_01 = predicted_hosp_01 / dlhs_beds
gen capacity_10 = predicted_hosp_10 / dlhs_beds
drop dlhs_beds

scatter capacity_01 rank_dlhs4, yline(1)
graphout x

export excel $covidpub/out/district_age_dist_cfr_hospitals, replace firstrow(variables)



exit
exit

/* compare with state-level PDF from Helath inventory 2019 */
use $covidpub/hospitals_dist_export.dta, clear

gen dlhs_pub_beds = dlhs4_perk_beds_tot / 1000 * pc11_population
gen dlhs_beds = dlhs4_perk_beds_pubpriv / 1000 * pc11_population
gen pc_beds = pc_perk_beds_pubpriv / 1000 * pc11_population

collapse (sum) dlhs_beds dlhs_pub_beds pc_beds, by(pc11_state_id pc11_state_name)

