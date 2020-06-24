global conditionlist copd asthma

/* import india prevalence csv */
import delimited using $covidpub/covid/csv/india_condition_prevalence.csv, varnames(1) clear
drop source
ren *, lower

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)
drop if condition == "Hypertension (2)"
replace condition = "hypertension" if condition == "Hypertension (1)"
replace condition = lower(condition)

/* create a new age-granular dataset and fill it according to the age bins */
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

/* drop the original fields and limit to ages close to our sample */
keep if inrange(age, 16, 90)
keep age prev*
drop prevalence

ren prev* india_prev*

/* save uk prevalences */
save $tmp/india_prevalences, replace
