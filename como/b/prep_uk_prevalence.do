//global conditionlist hypertension diabetes copd asthma
/* first import and calculate COPD rate, this is the only variable coming from its own source */
import delimited using $iec/covid/covid/csv/copd_mclean_rates.csv, clear

/* calculate the total population */
gen pop_total = pop_female + pop_male

/* take the weighted average of male and female rates */
gen prev_copd = rate100k_male*(pop_male / pop_total) + rate100k_female*(pop_female / pop_total)

/* convert the per 100k rate to a prevalence */
replace prev_copd = prev_copd / 100000

/* keep only 18 - 100 year olds */
keep if inrange(age, 18, 100)
keep age prev_copd
save $tmp/copd_uk_prev, replace

/* create full condition list */
global conditionlist diabetes_contr diabetes_uncontr hypertension_contr hypertension_uncontr hypertension_both asthma copd obese_1_2 obese_3

/* import uk data */
import delimited using $covidpub/covid/csv/uk_condition_prevalence.csv, varnames(1) clear
drop source v*

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)

/* replace names */
// replace condition = "diabetes_diagnosed" if condition == "Diabetes" */
replace condition = "diabetes_contr" if condition == "Diabetes (2)"
replace condition = "diabetes_uncontr" if condition == "Diabetes (2a)"
replace condition = "hypertension_contr" if condition == "Hypertension (3)"
replace condition = "hypertension_both" if condition == "Hypertension (3a)"
replace condition = "hypertension_uncontr" if condition == "Hypertension (3b)"
// replace condition = "hypertension_diagnosis" if condition == "Hypertension (1)" */
// replace condition = "hypertension_both2" if condition == "Hypertension (2)" */
// replace condition = "hypertension_biomarker2" if condition == "Hypertension (2a)" */
replace condition = "obese_1_2" if condition == "Obesity class 1-2"
replace condition = "obese_3" if condition == "Obesity class 3"
replace condition = lower(condition)


/* create a new dataset and fill it with a manual reshape */
set obs 100
gen age = _n

foreach condition in $conditionlist {
  gen prev_`condition' = .
  forval age = 1/100 {
    qui sum prevalence if condition == "`condition'" & inrange(`age', startage, endage)
    if `r(N)' > 0 {
      replace prev_`condition' = `r(mean)' if age == `age'
    }
  }
}
drop prevalence
keep age prev_*

/* Update 06/22: correct data input of COPD with calculations at the top of this file */
merge 1:1 age using $tmp/copd_uk_prev, keepusing(prev_copd) nogen

/* old code:
merge 1:1 age using $covidpub/covid/csv/uk_copd_prevalence, keepusing(prevalence) nogen
drop prev_copd
ren prevalence prev_copd */

/* drop the original fields and limit to ages in study */
keep if inrange(age, 18, 100)

/* rename these to the variables that match OpenSAFELY */
gen prev_bp_high = prev_hypertension_both
ren prev_asthma prev_asthma_no_ocs
ren prev_copd prev_chronic_resp_dz

ren prev* uk_prev*

/* save uk prevalences */
save $tmp/uk_prevalences, replace
