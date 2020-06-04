global comorbid_vars  age18_40 age40_50 age50_60 age60_70 age70_80 age80_ female male bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global comorbid_vars_no_age_sex bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

/* collapse the data to age-sex bins */
use $tmp/tmp_hr_data, clear

drop if age > 85
collapse (mean) risk_factor_* $comorbid_vars_no_age_sex [aw=wt], by(age)

/* bring in the NHS hazard ratios so we can recalculate on the binned means */
gen v1 = 0
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_age_sex, nogen
merge m:1 age using $tmp/uk_age_predicted_hr

/* create fully-adjusted continuous risk hazard model */
/* assume 50% men for now */
gen arisk_full = hr_full_age_cts * (male_hr_full * .5 + .5)
foreach v in $comorbid_vars_no_age_sex {
  replace arisk_full = arisk_full * ( (`v'_hr_full * `v') + (1 - `v'))
}

/* create age-sex risk */
gen arisk_simple = hr_age_sex_age_cts * (male_hr_age_sex * .5 + .5)
foreach v in $comorbid_vars_no_age_sex {
  replace arisk_simple = arisk_simple * ( (`v'_hr_age_sex * `v') + (1 - `v'))
}

/* put into logs */
foreach v in full simple {
  gen ln_risk_`v' = ln(risk_`v')
}

/* show results */
twoway ///
    (scatter ln_risk_full age) ///
    (scatter ln_risk_simple age) ///
    , legend(lab(1 "Fully adjusted") lab(2 "Age-sex only"))
graphout risk_aggregate

/* compare with same two things in microdata risk factors */
