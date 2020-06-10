/*****************************************/
/* transform NHS incidence data into dta */
/*****************************************/
import delimited using $covidpub/covid/csv/uk_nhs_incidence.csv, clear varnames(1)
replace prevalence = prevalence / 100

/* reshape it to wide */
gen x = 1
ren prevalence uk_prev_
reshape wide uk_prev_, i(x) j(condition) string
drop x

/* save NHS prevalence */
gen v1 = 0
save $tmp/uk_nhs_incidence, replace

/********************************************/
/* calculate risk factors at uk prevalences */
/********************************************/

/* uses UK incidence and condition hazard ratios to calculate population
  risk relative to the benchmark of 50-year-old women in the NHS study. */

/* open incidences */
use $tmp/uk_nhs_incidence, clear

/* merge in risk factors */
merge 1:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen
save $tmp/foo, replace

/* make sure no variable begins with "risk" so we can use risk* later */
cap ds risk*
if !_rc {
  display as error "Code below will break if a risk* variable already exists here."
  error 345
}

/* calculate the combined risk factor one categorical variable at a time */
gen risk_gender = (uk_prev_female * female_hr_full + uk_prev_male * male_hr_full) / (uk_prev_male + uk_prev_female)

/* age categories -- risk_age is the aggregate risk multiplier for the UK's age structure */
gen risk_age = 0
global agelist 18_40 40_50 50_60 60_70 70_80 80_
foreach agecat in $agelist {
  replace risk_age = risk_age + uk_prev_age`agecat' * age`agecat'_hr_full
}
replace risk_age = risk_age / (uk_prev_age18_40 + uk_prev_age40_50 + uk_prev_age50_60 + uk_prev_age60_70 + uk_prev_age70_80 + uk_prev_age80_)

/* all health conditions */
gen risk_condition = 1
foreach v in $hr_biomarker_vars $hr_gbd_vars {
  replace risk_condition = risk_condition * (uk_prev_`v' * `v'_hr_full + (1 - uk_prev_`v'))
}

/* combine health and gender into one risk factor */
gen risk_non_age = risk_condition * risk_gender

/* calculate total UK risk multiplier in each age bin */
foreach agecat in $agelist {
  gen risk_age_`agecat' = risk_non_age * age`agecat'_hr_full
}

/* save UK risk multipliers */
ren risk* uk_risk*
save $tmp/uk_risk_factor, replace

/*****************************************************************/
/* create a simulated UK data with the age-specific risk factors */
/*****************************************************************/
use $tmp/uk_risk_factor, clear

/* expand to one row per age */
expand 67
gen age = _n + 17

/* bring in cts age risk factor */
merge 1:1 age using $tmp/uk_age_predicted_hr, nogen keep(master match)

/* create continuous uk age-specific risk */
gen uk_risk = hr_full_age_cts * uk_risk_non_age

save $tmp/uk_sim_age_fixed, replace

/****************************************************************************/
/* create a version using age-variant conditions with GBD and external data */
/****************************************************************************/
use $tmp/uk_prevalences, clear

merge 1:1 age using $health/gbd/gbd_nhs_conditions_uk, nogen
drop *upper *lower
keep if inrange(age, 18, 84)

/* rename all conditions to vars matching the HR names */
drop gbd_diabetes

/* merge in risk factors */
gen v1 = 0
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen

drop *granular
ren uk_prev_diabetes_biomarker uk_prev_diabetes_uncontr
ren uk_prev_hypertension_biomarker uk_prev_bp_high
drop uk_prev_hyp* uk_prev_diabetes_both uk_prev_diabetes_diagnosed
ren gbd_* uk_prev_*

/* drop hRs we don't use */
drop *age*hr_full *bp_not_high*

foreach v of varlist *hr_full {
  local x = substr("`v'", 1, strlen("`v'") - 8)
  cap confirm variable uk_prev_`x'
  if _rc {
    di "Missing `x'"
  }
}

/* bring in age-invariant prevalences for the fields we don't have otherwise */
merge m:1 v1 using $tmp/uk_nhs_incidence, nogen keepusing( *bmi_not_obese *bmi_obeseI *bmi_obeseII *bmi_obeseIII *asthma_no_ocs *diabetes_contr *cancer_non_haem_1_5 *cancer_non_haem_5 *haem_malig_1_5 *haem_malig_5 *organ_transplant *spleen_dz)

/* bring in cts age risk factor */
merge 1:1 age using $tmp/uk_age_predicted_hr, nogen keep(master match) keepusing(hr_full_age_cts)

/* set male share at 49.9 following OpenSafely */
gen uk_prev_male = 0.499

/* multiply through all the risk factors */
gen uk_risk = 1
global os_vars asthma_no_ocs diabetes_contr cancer_non_haem_1_5 cancer_non_haem_5 haem_malig_1_5 haem_malig_5  organ_transplant spleen_dz 
global all_vars male $hr_biomarker_vars $hr_gbd_vars 
foreach v in $all_vars {
  replace uk_risk = uk_risk * (uk_prev_`v' * `v'_hr_full + (1-uk_prev_`v'))
  drop uk_prev_`v'
}
replace uk_risk = uk_risk * hr_full_age_cts
sum uk_risk

save $tmp/uk_sim_age_flex, replace

/************************************************************************************/
/* can we replicate the overall mortality rate by multiplying all the risk factors? */
/************************************************************************************/
use $tmp/foo, clear
 
global all_vars $age_vars male $hr_biomarker_vars $hr_gbd_vars

gen risk = 1
foreach v in $all_vars {
  replace risk = risk * (uk_prev_`v' * `v'_hr_full + (1-uk_prev_`v'))
  drop uk_prev_`v'
}
sum risk

/* trying to match the population mortality rate relative to the reference group mortality. */
/* reference group mortality = 0.011568%
   total population risk: 0.03261%

   odds ~= 2.81. Compare with 3.44. In the ballpark--
                 probably off from rounding errors in
                 recording prevalences.
*/
