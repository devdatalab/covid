//global conditionlist hypertension diabetes copd asthma

/* create full condition list */
global conditionlist diabetes_diagnosed diabetes_biomarker diabetes_both hypertension_diagnosed hypertension_biomarker hypertension_both asthma copd

/* import uk data */
import delimited using $covidpub/covid/csv/uk_condition_prevalence2.csv, varnames(1) clear
drop source v*

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)

/* replace names */
replace condition = "diabetes_diagnosed" if condition == "Diabetes"
replace condition = "diabetes_both" if condition == "Diabetes (2)"
replace condition = "diabetes_biomarker" if condition == "Diabetes (2a)"
replace condition = "hypertension_both" if condition == "Hypertension (3)"
replace condition = "hypertension_biomarker" if condition == "Hypertension (3a)"
replace condition = "hypertension_diagnosis" if condition == "Hypertension (1)"
replace condition = "hypertension_both2" if condition == "Hypertension (2)"
replace condition = "hypertension_biomarker2" if condition == "Hypertension (2a)"
replace condition = "asthma" if condition == "Asthma"
replace condition = "copd" if condition == "COPD"

// drop if condition == "Hypertension (2)"
// replace condition = "hypertension" if condition == "Hypertension (1)"
// replace condition = lower(condition)

/* make prevalence numeric */
// replace prevalence = substr(prevalence, 1, strlen(prevalence) - 1)
// destring prevalence, replace

/* create a new dataset and fill it with a manual reshape */
set obs 100
gen age = _n

foreach condition in $conditionlist {
  gen prev_`condition' = .
  forval age = 1/100 {
    sum prevalence if condition == "`condition'" & inrange(`age', startage, endage)
    if `r(N)' > 0 {
      replace prev_`condition' = `r(mean)' if age == `age'
    }
  }
  replace prev_`condition' = prev_`condition' / 100
}

/* drop the original fields and limit to ages with data */
keep if inrange(age, 16, 90)
keep age prev*
drop prevalence

ren prev* uk_prev*

/* save uk prevalences */
save $tmp/uk_prevalences, replace


