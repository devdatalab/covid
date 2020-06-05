global conditionlist hypertension diabetes copd asthma

/* import uk data */
import delimited using $covidpub/covid/csv/uk_condition_prevalence.csv, varnames(1) clear
drop source

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)
drop if condition == "Hypertension (2)"
replace condition = "hypertension" if condition == "Hypertension (1)"
replace condition = lower(condition)

/* make prevalence numeric */
replace prevalence = substr(prevalence, 1, strlen(prevalence) - 1)
destring prevalence, replace

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


