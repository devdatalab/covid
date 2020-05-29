/* get a poverty measure from...  */
use $secc/final/collapse/village_consumption_imputed_pc11, clear

/* get district identifiers */
merge 1:1 pc11_state_id pc11_village_id using $keys/pc11_village_key, keepusing(pc11_district_id)
keep if _merge == 3
drop _merge

/* collapse to district */
collapse (mean) secc_cons_per_cap [aw=pc11_pop], by(pc11_state_id pc11_district_id)
save $tmp/pc11_cons, replace

/* open risk factor file from examine_risk_factors.do  */
use $tmp/rfs, clear

/* collapse risk factors to district level */
/* [note this is trusting district-level age distributions to be correct --
    which it won't be given only 1000 obs per district. alternately we could
    do some kind of imputation here to bring down the noise level-- reweight
    the age distribution based on the true age distribution from the SECC,
    but keep the conditions as they are.] */
collapse (mean) hr_full_bp_high bp_high *resp* ln_rf_full_nond_conditions *rf_full_abd_c *rf_full_diab ln_rf_full_c rf_full_c rf_simple_agesex_c ln_rf_simple_agesex_c [aw=wt], by(pc11_state_id pc11_district_id)

/* merge in our best measure of poverty -- currently access to  */
merge 1:1 pc11_state_id pc11_district_id using $covidpub/demography/pc11/water_district_pc11, keepusing(pc11r_hl_dw_loc_inprem_sh pc11u_hl_dw_loc_inprem_sh) gen(_mw)
drop if _mw == 2
drop _mw

merge 1:1 pc11_state_id pc11_district_id using $covidpub/demography/pc11/dem_district_pc11, keepusing(pc11r_pca_tot_p pc11u_pca_tot_p) gen(_md)
drop if _md == 2
drop _md

/* get consumption data */
merge 1:1 pc11_state_id pc11_district_id using $tmp/pc11_cons
drop if _merge == 2
drop _merge
ren secc_cons_per_cap cons

/* generate share with water */
gen water_share = ((pc11r_hl_dw_loc_inprem_sh * pc11r_pca_tot_p) + (pc11u_hl_dw_loc_inprem_sh * pc11u_pca_tot_p)) / (pc11r_pca_tot_p + pc11u_pca_tot_p)

/* examine risk curves as a function of the water share */
binscatter rf_full_c rf_simple_agesex_c water_share, 
graphout rf_water

binscatter ln_rf_full_c ln_rf_simple_agesex_c water_share, 
graphout ln_rf_water

/* examine correlation of risk factors with water share */
reg rf_simple_agesex_c water_share
reg rf_full_c water_share

reg rf_full_diab water_share
reg ln_rf_full_diab water_share

reg ln_rf_full_abd_c water_share
reg ln_rf_simple_agesex_c water_share

/* repeat analysis with secc consumption */
binscatter rf_full_c rf_simple_agesex_c cons, 
graphout rf_cons

binscatter ln_rf_full_c ln_rf_simple_agesex_c cons, 
graphout ln_rf_cons

reg rf_simple_agesex_c cons
reg rf_full_c cons

reg rf_full_diab cons
reg ln_rf_full_diab cons

reg ln_rf_full_abd_c cons
reg ln_rf_simple_agesex_c cons

/* various conditions vs income */
binscatter rf_full_diab cons
graphout diabetes_cons

/* compare resp conditions with income */
foreach v of varlist *resp* {
  binscatter `v' cons
  graphout `v'_cons
}

/* hypertension vs. income */
binscatter bp_high cons
graphout hyp_cons

