cap prog drop labelstuff
prog def labelstuff
  label var rf_full_age_d "Full, age only, discrete"
  label var rf_full_age_c "Full, age only, continuous"
  label var rf_simple_age_d "Simple, age only, discrete"
  label var rf_simple_age_c "Simple, age only, continuous"
  label var rf_full_agesex_d "Full, age+sex, discrete"
  label var rf_full_agesex_c "Full, age+sex, continuous"
  label var rf_simple_agesex_d "Simple, age+sex, discrete"
  label var rf_simple_agesex_c "Simple, age+sex, continuous"
  label var rf_full_nond_conditions "Health conditions other than diabetes"
  label var rf_full_diab "Diabetes"
  label var rf_full_abd_c "Age, sex, conditions other than diabetes (continuous)"
  label var rf_full_abd_d "Age, sex, conditions other than diabetes (discrete)"
  label var rf_full_c "Fully adjusted (continuous)"
  label var rf_full_d "Fully adjusted (discrete)"
  label var ln_rf_full_age_d "Full, age only, discrete"
  label var ln_rf_full_age_c "Full, age only, continuous"
  label var ln_rf_simple_age_d "Simple, age only, discrete"
  label var ln_rf_simple_age_c "Simple, age only, continuous"
  label var ln_rf_full_agesex_d "Full, age+sex, discrete"
  label var ln_rf_full_agesex_c "Full, age+sex, continuous"
  label var ln_rf_simple_agesex_d "Simple, age+sex, discrete"
  label var ln_rf_simple_agesex_c "Simple, age+sex, continuous"
  label var ln_rf_full_nond_conditions "Health conditions other than diabetes"
  label var ln_rf_full_diab "Diabetes"
  label var ln_rf_full_abd_c "Age, sex, conditions other than diabetes (continuous)"
  label var ln_rf_full_abd_d "Age, sex, conditions other than diabetes (discrete)"
  label var ln_rf_full_c "Fully adjusted (continuous)"
  label var ln_rf_full_d "Fully adjusted (discrete)"
end

/* open data with individual-specific hazard ratios */
use $tmp/combined, clear

/* combine the age factors into single variables */
gen hr_full_age_discrete = hr_full_age18_40 * hr_full_age40_50 * hr_full_age50_60 * hr_full_age60_70 * hr_full_age70_80 * hr_full_age80_
gen hr_age_sex_age_discrete = hr_age_sex_age18_40 * hr_age_sex_age40_50 * hr_age_sex_age50_60 * hr_age_sex_age60_70 * hr_age_sex_age70_80 * hr_age_sex_age80_

/* drop the individual age vars to avoid confusion */
drop *40* *60* *80*

/* rename "age_sex" to "simple" so i don't get confused by these repeated words */
ren *age_sex* *simple*

/*********************************************/
/* store things we want to graph as rf_ vars */
/*********************************************/

/* age only */
gen rf_full_age_d = hr_full_age_discrete
gen rf_full_age_c = hr_full_age_cts
gen rf_simple_age_d = hr_simple_age_discrete
gen rf_simple_age_c = hr_simple_age_cts

/* add sex */
gen rf_full_agesex_d = hr_full_age_discrete * hr_full_female
gen rf_full_agesex_c = hr_full_age_cts * hr_full_female
gen rf_simple_agesex_d = hr_simple_age_discrete * hr_simple_female
gen rf_simple_agesex_c = hr_simple_age_cts * hr_simple_female

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

/* create log version of all risk factors in case it affects the collapse */
foreach v of varlist rf_* {
  gen ln_`v' = ln(`v')
}
labelstuff
save $tmp/rfs, replace

/* collapse to age-level data */
collapse (mean) rf* ln* [aw=wt], by(age)

/* label everything */
labelstuff

sort age

save $tmp/ages, replace
use $tmp/ages, clear

/* slowly build comparison between full and adjusted model to see what makes them change */

/* age and sex only */
sc rf_simple_agesex_c rf_full_agesex_c , name(agesex_only)
/* good -- no difference */

/* and add non-diabetes conditions and fully adjusted model */
sc rf_simple_agesex_c rf_full_agesex_c rf_full_abd_c rf_full_c, name(full_model)

/* compare final model to dumb model */
sc rf_simple_agesex_c rf_full_c , name(full_v_simple)

/* graph relative risk increase from age-sex model to full model */
/* use logs so this is in percentage terms */
gen risk_change = ln_rf_full_c - ln_rf_simple_agesex_c
line risk_change age, lwidth(medthick)
graphout risk_change



/* run full model in logs */
sc ln_rf_full_agesex_c ln_rf_full_abd_c ln_rf_full_c ln_rf_simple_agesex_c, name(full_model_logs) yscale(r(-5 5))

sc rf_full_age_c rf_full_age_d, name(full_age_cd)
sc rf_simple_age_c rf_simple_age_d, name(simple_age_cd)


/* compare mortality risk at ages 40 and 50 */
list age rf_full_age_c rf_simple_agesex_c ln_rf_full_age_c ln_rf_simple_agesex_c if inlist(age, 40, 50)



/* aggregate risk by collapsing across deaths */
