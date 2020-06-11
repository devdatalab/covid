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

/* collapse to the state-age level */
collapse (mean) rf_* $hr_biomarker_vars $hr_selfreport_vars [aw=wt], by(age pc11_state_id pc11_state_name)

/* bring in GBD average age-specific conditions by state */
merge 1:1 age pc11_state_id using $health/gbd/gbd_india_states, keep(match) nogen

/* bring back hazard ratios which were lost in the collapse */
gen v1 = 0
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen

/* add GBD risk factors, starting from biomarker model */
save $tmp/foo, replace

use $tmp/foo, clear
gen rf_full_all = rf_full_biomarkers
foreach condition in $hr_gbd_vars {
  replace rf_full_all = rf_full_all * ((`condition'_hr_full * `condition') + (1 - `condition'))
}
  
/* create a risk factor that is health conditions only */
gen rf_conditions = rf_full_all / rf_full_agesex

/* create non-biomarker and biomarker conditions risk factor */
gen rf_nonbio_conditions = rf_full_all / rf_full_biomarkers
gen rf_bio_conditions = rf_full_biomarkers / rf_full_agesex

/* get state-level population */
merge m:1 pc11_state_id using $pc11/pc11_pca_state_clean, keepusing(pc11_pca_tot_p) keep(master match) nogen

/* get state-level age-specific population */
merge m:1 pc11_state_id age using $tmp/state_pop, keepusing(state_pop) keep(master match) nogen
ren state_pop state_age_pop

/* assume a mortality rate of 1% for risk factor 1 and calculate deaths */
global mortrate 0.01
foreach v in simple full_biomarkers full_all conditions {
  gen deaths_`v' = rf_`v' * state_age_pop * $mortrate
}

save $tmp/sofar, replace


/* summarize risk factors at age 50 */
use $tmp/sofar, clear

exit

/* experiment 1: do risk factors change substantially across states by age? */
/* rank each state in each age bin */
foreach v in simple full_biomarkers conditions full_all {
  bys age: egen rank_age_`v' = rank(rf_`v'), field
}
list age rank_age_simple rank_age_conditions if pc11_state_name == "uttar pradesh"

/* experiment 2: who has best/worst risk factors at age 40 */
drop rank*
preserve
keep if age == 40
foreach v in simple full_biomarkers conditions full_all nonbio_conditions {
  egen rank_`v' = rank(rf_`v'), field
}
sort rank_conditions
list pc11_state_name rank*
restore

/* scatter biomarker conditions vs. non-biomarker conditions at age 40 */
scatter rf_nonbio_conditions rf_bio_conditions if age == 40, mlabel(pc11_state_name) msize(tiny)
graphout bio_nonbio_40

scatter rf_nonbio_conditions rf_bio_conditions if age == 30, mlabel(pc11_state_name) msize(tiny)
graphout bio_nonbio_30

scatter rf_nonbio_conditions rf_bio_conditions if age == 60, mlabel(pc11_state_name) msize(tiny)
graphout bio_nonbio_60

reg rf_nonbio_conditions rf_bio_conditions, absorb(age)
corr rf_nonbio_conditions rf_bio_conditions if age == 20
corr rf_nonbio_conditions rf_bio_conditions if age == 40
corr rf_nonbio_conditions rf_bio_conditions if age == 60

/* collapse to deaths by state according to each measure */
use $tmp/sofar, clear

/* drop kerala where there is no data */
drop if pc11_state_name == "kerala"

collapse (sum) deaths* (firstnm) pc11_pca_tot_p, by(pc11_state_id pc11_state_name)
foreach v of varlist death* {
  replace `v' = `v' / pc11_pca_tot_p
}

/* forecast mortality rate across states */
twoway (scatter deaths_simple deaths_full_all, mlabel(pc11_state_name) msize(tiny)) (line deaths_full_all deaths_full_all) ///
    , legend(off) ytitle("Age-Sex Only") xtitle("Full Model")
graphout state_mort_rate

save ~/iec/output/pn/test, replace

/* just show the health condition risk factors by state */
use $tmp/sofar, clear

collapse (mean) rf_* [aw=state_age_pop], by(pc11_state_name pc11_state_id)

/* calculate ranks */
foreach v of varlist rf_* {
  local v = substr("`v'", 4, .)
  egen rank_`v' = rank(rf_`v'), field
}

/* list risk factors for age, biomarker, and nonbiomarker conditions */
sort rank_full_agesex
list pc11_state_name rank_simple rank_bio_conditions rank_nonbio_conditions rank_full_all

format rf* %6.2f
list pc11_state_name rf_simple rf_bio_conditions rf_nonbio_conditions rf_full_all
