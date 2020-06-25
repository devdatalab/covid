/**********************************/
/* Create wide hazard ratio files */
/**********************************/

/* Convert HR CSV to Stata */
import delimited $covidpub/covid/csv/uk_nhs_hazard_ratios.csv, clear

/* label variables */
lab var hr_age_sex "hazard ratio age-sex adjusted"
lab var hr_age_sex_low "hazard ratio age-sex adjusted lower CI"
lab var hr_age_sex_up "hazard ratio age-sex adjusted upper CI"
lab var hr_full "hazard ratio fully adjusted"
lab var hr_full_low "hazard ratio fully adjusted lower CI"
lab var hr_full_up "hazard ratio fully adjusted upper CI"
lab var hr_full_ec "hazard ratio fully adjusted early censoring"
lab var hr_full_low_ec "hazard ratio fully adjusted early censoring lower CI"
lab var hr_full_up_ec "hazard ratio fully adjusted early censoring upper CI"

/* shorten age-sex HRs */
ren *age_sex* *simp*

/* save as dta file */
save $tmp/uk_nhs_hazard_ratios, replace

/* raw data has risk factors in long format-- reshape them to wide */
/* loop over two types of hazard ratios */
foreach hr in hr_full hr_simp {

  /* open the long format HRs */
  use $tmp/uk_nhs_hazard_ratios, clear  

  /* keep the risk factors, the desired hazard ratio, and the confidence interval */
  keep variable `hr' `hr'_low `hr'_up

  /* transform hazard ratio into a relative risk, assuming base mortality rate of 1% */
  replace `hr' = (1 - exp(`hr' * ln(1 - 0.01))) / 0.01

  /* replace the confidence interval with a standard error.
  These are odds ratios. CIs for log odds are symmetric. */
  gen `hr'_lnse = (ln(`hr') - ln(`hr'_low)) / 1.96
  gen `hr'_lnse2 = (ln(`hr'_up) - ln(`hr')) / 1.96

  /* reshape them to wide format */
  gen v1 = 0
  keep `hr' `hr'_lnse v1 variable
  reshape wide `hr' `hr'_lnse, j(variable) i(v1) string
  ren `hr'_lnse* *_hr_lnse
  ren `hr'* *_`hr'
  
  /* save the wide hazard ratios with standard errors */
  save $tmp/uk_nhs_hazard_ratios_flat_`hr', replace
}

/* convert continuous age HRs to stata */
import delimited $covidpub/covid/csv/uk_age_predicted_hr.csv, clear
ren ln_hr_age_sex ln_hr_simp
gen hr_simp_age_cts = exp(ln_hr_simp)
gen hr_full_age_cts = exp(ln_hr_full)
drop ln_*
save $tmp/uk_age_predicted_hr, replace
