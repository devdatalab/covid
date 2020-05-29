/********************************************/
/* calculate risk factors at uk prevalences */
/********************************************/

/* uses UK incidence and condition hazard ratios to calculate population
  risk relative to the benchmark of 50-year-old women in the NHS study. */


/* open incidences */
use $tmp/uk_nhs_incidence, clear

/* merge risk factors */
merge 1:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_fully_adj

/* make sure no variable begins with "risk" so we can use risk* later */
cap ds risk*
if !_rc {
  display as error "Code below will break if a risk* variable already exists here."
  error 345
}

/* calculate the combined risk factor one categorical variable at a time */
gen risk_gender = (uk_prev_female * female_hr_fully_adj + uk_prev_male * male_hr_fully_adj) / (uk_prev_male + uk_prev_female)

/* age categories */
gen risk_age = 0
global agelist 18_40 40_50 50_60 60_70 70_80 80_
foreach agecat in $agelist {
  replace risk_age = risk_age + uk_prev_age`agecat' * age`agecat'_hr_fully_adj
}
replace risk_age = risk_age / (uk_prev_age18_40 + uk_prev_age40_50 + uk_prev_age50_60 + uk_prev_age60_70 + uk_prev_age70_80 + uk_prev_age80_)

/* bmi */
gen risk_bmi = 0
foreach bmi in not_obese obeseI obeseII obeseIII {
  replace risk_bmi = risk_bmi + uk_prev_bmi_`bmi' * bmi_`bmi'_hr_fully_adj
}
replace risk_bmi = risk_bmi / (uk_prev_bmi_not_obese + uk_prev_bmi_obeseI + uk_prev_bmi_obeseII + uk_prev_bmi_obeseIII)

/* bp */
gen risk_bp = (uk_prev_bp_high * bp_high_hr_fully_adj + uk_prev_bp_not_high * bp_not_high_hr_fully_adj) / (uk_prev_bp_not_high + uk_prev_bp_high)

/* note that risk factors stop adding up to 1 after this point, as the safe group is omitted */
/* we don't need the denominator for these since they add up to 1 by construction */
/* implicitly assigning OR = 1 to the safe group */

/* diabetes -- ignore controlled and no measure categories */
gen risk_diab = diabetes_uncontr_hr_fully_adj * uk_prev_diabetes_uncontr + (1 - uk_prev_diabetes_uncontr)

/* cancer -- check with Ali on this one -- assumes we ignore all older cancers */
gen risk_cancer_non_haem_1 = cancer_non_haem_1_hr_fully_adj * uk_prev_cancer_non_haem_1 + (1 - uk_prev_cancer_non_haem_1)

/* other factors */
foreach condition in chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz chronic_resp_dz {
  gen risk_`condition' = `condition'_hr_fully_adj * uk_prev_`condition' + (1 - uk_prev_`condition')
}

/* combine risk factors into a single UK risk factor */
/* this will be relative to a 50-59 yo woman with no pre-existing conditions */
gen uk_risk_factor = 1
foreach v of varlist risk* {
  replace uk_risk_factor = uk_risk_factor * `v'
}
sum uk_risk_factor

/* calculate UK risk factors in each age bin */
gen uk_non_age_risks = uk_risk_factor / risk_age
foreach agecat in $agelist {
  gen uk_risk_age_`agecat' = uk_non_age_risks * age`agecat'_hr_fully_adj
}
save $tmp/uk_risk_factor, replace

/*****************************************************************/
/* create a simulated UK data with the age-specific risk factors */
/*****************************************************************/
use $tmp/uk_risk_factor, clear

expand 1000
gen age = uniform() * 82 + 18
gen     uk_risk = uk_risk_age_18_40 if inrange(age, 18, 40)
replace uk_risk = uk_risk_age_40_50 if inrange(age, 40, 50)
replace uk_risk = uk_risk_age_50_60 if inrange(age, 50, 60)
replace uk_risk = uk_risk_age_60_70 if inrange(age, 60, 70)
replace uk_risk = uk_risk_age_70_80 if inrange(age, 70, 80)
replace uk_risk = uk_risk_age_80_   if inrange(age, 80, 100)
keep age uk_risk
gen ln_uk_risk = ln(uk_risk)
save $tmp/uk_sim, replace

