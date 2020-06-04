/* function to scatter multiple variables over age */
cap prog drop sc
prog def sc

  syntax varlist, [name(string) yscale(passthru)]
  tokenize `varlist'

  /* set a default yscale */
  if mi("`yscale'") local yscale yscale(log) ylabel(.125 .25 1 4 16 64)

  /* set a default name */
  if mi("`name'") local name euripides
  
  /* loop over the outcome vars */
  while (!mi("`1'")) {

    /* store the variable label */
    local label : variable label `1'

    /* add the line plot for this variable to the twoway command string */
    local command `command' (line `1' age, `yscale' xtitle("`label'") ytitle("Mortality Hazard Ratio") lwidth(medthick) )

    /* get the next variable in the list */
    mac shift
  }

  /* draw the graph */
  twoway `command'
  graphout `name'
end

global comorbid_vars  age18_40 age40_50 age50_60 age60_70 age70_80 age80_ female male bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global comorbid_conditions_no_diab bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz 

global comorbid_vars_no_age_sex bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

/* collapse the data to age-sex bins */
use $tmp/tmp_hr_data, clear

/* drop redundant risk factors built in other file since we rebuild here more granularly */
drop risk_factor*

/* drop old folks */
drop if age > 85

/*********************************************************/
/* REBUILD RISK FACTORS WHICH SOMEHOW ENDED UP DIFFERENT */
/*********************************************************/

/* create combined discrete age risk factors */
gen hr_full_age_discrete = hr_full_age18_40 * hr_full_age40_50 * hr_full_age50_60 * hr_full_age60_70 * hr_full_age70_80 * hr_full_age80_
gen hr_age_sex_age_discrete = hr_age_sex_age18_40 * hr_age_sex_age40_50 * hr_age_sex_age50_60 * hr_age_sex_age60_70 * hr_age_sex_age70_80 * hr_age_sex_age80_

/* drop the individual age vars to avoid confusion */
drop *40* *60* *80*

/* rename "age_sex" to "simple" so i don't get confused by these repeated words */
ren *age_sex* *simple*

/* age only */
gen rf_full_age_d = hr_full_age_discrete
gen rf_full_age_c = hr_full_age_cts
gen rf_simple_age_d = hr_simple_age_discrete
gen rf_simple_age_c = hr_simple_age_cts

/* add sex */
gen rf_full_agesex_d = hr_full_age_discrete * hr_full_male
gen rf_full_agesex_c = hr_full_age_cts * hr_full_male
gen rf_simple_agesex_d = hr_simple_age_discrete * hr_simple_male
gen rf_simple_agesex_c = hr_simple_age_cts * hr_simple_male

/* add conditions other than diabetes */
gen rf_full_nond_conditions = 1
foreach condition in $comorbid_conditions_no_diab {
  replace rf_full_nond_conditions = rf_full_nond_conditions * hr_full_`condition'
}

/* generate diabetes only */
gen rf_full_diab = hr_full_diabetes_uncontr

/* generate age + sex + non-diabetes conditions */
gen rf_full_abd_d = rf_full_nond_conditions * rf_full_agesex_d
gen rf_full_abd_c = rf_full_nond_conditions * rf_full_agesex_c

/* generate fully adjusted */
gen rf_full_d = rf_full_abd_d * hr_full_diabetes_uncontr 
gen rf_full_c = rf_full_abd_c * hr_full_diabetes_uncontr 

collapse (mean) rf_* $comorbid_vars_no_age_sex [aw=wt], by(age)

/* bring in the NHS hazard ratios so we can recalculate on the binned means */
gen v1 = 0
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_full, nogen
merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_hr_age_sex, nogen
merge m:1 age using $tmp/uk_age_predicted_hr, keep(match master) nogen

/* bring in some GBD prevalence data */
merge m:1 age using $tmp/india_prevalences, keep(match master) nogen

/* bring in NY odds ratios */
merge m:1 age using $tmp/nystate_or, keep(match master) nogen

/* create fully-adjusted continuous risk hazard model */
/* assume 47% men for now in both simple and full models */
gen arisk_full = hr_full_age_cts * (male_hr_full * .47 + .53)
foreach v in $comorbid_vars_no_age_sex {
  replace arisk_full = arisk_full * ( (`v'_hr_full * `v') + (1 - `v'))
}

/* create aggregate risk from simple model */
gen arisk_simple = hr_age_sex_age_cts * (male_hr_age_sex * .47 + .53)

/* label micro data and aggregate risk models */
label var arisk_simple "aggregate age-sex only (simple) model"
label var arisk_full   "aggregate fully adjusted model"
label var rf_simple_agesex_c "microdata age-sex only (simple) model"
label var rf_full_c "microdata fully adjusted model"

/* create an aggregate risk model using GBD prevalences for respiratory disease */
/* note: we first divide out the old respiratory factor and stick in the new */
gen     arisk_gbd = arisk_full / ( (chronic_resp_dz_hr_full * chronic_resp_dz) + (1 - chronic_resp_dz))
replace arisk_gbd = arisk_gbd  * ( (chronic_resp_dz_hr_full * india_prev_copd) + (1 - india_prev_copd))
label var arisk_gbd "full w/COPD from GBD"

/* create a fully adjusted model using NY odds ratios instead of NHS */
gen arisk_ny = arisk_full
foreach v in bp_high diabetes_uncontr chronic_heart_dz kidney_dz chronic_resp_dz {

  /* divide out the old aggregate effect */
  replace arisk_ny = arisk_ny / ( (`v'_hr_full * `v') + (1 - `v'))

  /* multiply in the age-specific NY version */
  replace arisk_ny = arisk_ny * ( (ny_or_`v' * `v') + (1 - `v'))
}
label var arisk_ny "full w/NY age-specific ORs for major conditions"

/* save a temporary version of the data */
save $tmp/aggs, replace

/* compare microdata risk factor to aggregate risk factor models */
sc arisk_full rf_full_c arisk_simple rf_simple_agesex_c, name(agg_v_micro)

/* compare full model to GBD-COPD model */
sc arisk_full arisk_simple arisk_gbd, name(vs_gbd_copd)

/* compare full model to NY OR model */
sc arisk_full arisk_ny, name(vs_ny)


/* show results */
sort age
twoway ///
    (line ln_arisk_full age) ///
    (line ln_arisk_simple age) ///
    , legend(lab(1 "Fully adjusted") lab(2 "Age-sex only"))
graphout arisk_aggregate

/* compare with same two things in microdata risk factors */
twoway ///
    (line ln_rf_full_cts age) ///
    (line ln_rf_simple_cts age) ///
    , legend(lab(1 "Fully adjusted") lab(2 "Age-sex only"))
graphout mrisk_aggregate


/*********************/
/* explore weirdness */
/*********************/
use $tmp/combined, clear

/* slowly build up the point at which 30-year-olds end up sicker in the full model */
gen rf_full = hr_full_age_cts
gen rf_simple = hr_age_sex_age_cts

sum rf_full rf_simple if age == 30

replace rf_full = rf_full * hr_full_male
replace rf_simple = rf_simple * hr_age_sex_male

sum rf_full rf_simple if age == 30

