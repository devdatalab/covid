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

/* save as dta file */
save $tmp/uk_nhs_hazard_ratios, replace

/* loop over two types of hazard ratios */
foreach hr in hr_full hr_age_sex {

  /* call a short python funciton to flatten our selected HR value into an array */
  /* [basically doing a reshape] */
  cd $ddl/covid/como
  shell python -c "from b.flatten_hr_data import flatten_hr_data; flatten_hr_data('`hr'', '$tmp/uk_nhs_hazard_ratios.dta', '$tmp/uk_nhs_hazard_ratios_flat_`hr'.csv')"

  /* read in the flat csv and save as a stata file */
  import delimited $tmp/uk_nhs_hazard_ratios_flat_`hr'.csv, clear

  /* save as dta */
  save $tmp/uk_nhs_hazard_ratios_flat_`hr', replace
}

/* convert continuous age HRs to stata */
import delimited $covidpub/covid/csv/uk_age_predicted_hr.csv, clear
gen hr_age_sex_age_cts = exp(ln_hr_age_sex)
gen hr_full_age_cts = exp(ln_hr_full)
drop ln_*
save $tmp/uk_age_predicted_hr, replace

