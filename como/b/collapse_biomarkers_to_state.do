/* open clean DLHS / AHS */
use $tmp/combined, clear

/* rename simple model to simple for less confusion */
ren *age_sex* *simple*

/* create naive age-sex risk factor (cts) */
gen rf_simple = hr_simple_age_cts * hr_simple_male

/* create age-sex component of biomarker risk factor */
gen rf_full_agesex = hr_full_age_cts * hr_full_male

/* add biomarkers */
gen rf_full_biomarkers = rf_full_agesex
foreach condition in $hr_biomarker_vars {
  replace rf_full_biomarkers = rf_full_biomarkers * hr_full_`condition'
}

/* collapse to the state level */
collapse (mean) rf_* $hr_biomarker_vars $hr_selfreport_vars [aw=wt], by(age pc11_state_id pc11_state_name)

/* bring in GBD average age-specific conditions by state */
merge 1:1 age pc11_state_id using $health/gbd/gbd_india_states, keep(match) nogen

/* add GBD risk factors */
gen rf_full_all = rf_full_biomarkers
foreach condition in $hr_gbd_vars {
  replace rf_full_all = rf_full_all * hr_full_`condition'
}

/* get state-level total population */
merge m:1 pc11_state_id using $pc11/pc11_pca_state_clean, keepusing(pc11_pca_tot_p) keep(master match) nogen

/* get state-level age-specific population */
//// need to build this

/* assume a mortality rate of 1% for risk factor 1 and calculate deaths */
global mortrate 0.01
foreach v in simple full_biomarkers full_all {
  gen deaths_`v' = rf_`v' * state_age_pop * $mortrate
}

save $tmp/sofar, replace


exit

/* summarize risk factors at age 50 */
use $tmp/sofar, clear

/* generate each state's rank on each risk factor */
keep if inrange(age, 40, 65)
collapse (mean) rf*, by(pc11_state_id pc11_state_name)

foreach v in simple full_biomarkers full_all {
  egen rank_`v' = rank(rf_`v'), field
}

/* #1 is the most at risk */
sort rank_full_all
list pc11_state_name rank_simple rf_simple rank_full_all rf_full_all 

