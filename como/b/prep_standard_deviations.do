/* GBD */
/* do GBD for both countries */
foreach geo in uk india {
  /* calculate standard errors from teh GBD data */
  use $health/gbd/gbd_nhs_conditions_`geo', clear

  /* drop all ages and age standardized */
  drop if age < 0

  /* for each risk factor calculate the standard deviation */
  foreach var in $hr_gbd_vars {

    /* take the log of each prevalence */
    gen `var'_log_diff1 = log10(gbd_`var'_upper) - log10(gbd_`var')
    gen `var'_log_diff2 =  log10(gbd_`var') - log10(gbd_`var'_lower)

    /* take the mean of the standard deviation */
    egen logsd_`var' = rmean(`var'_log_diff1 `var'_log_diff2)

    /* drop unneeded variabels */
    drop `var'_log_diff1 `var'_log_diff2
  }

  keep age *logsd*
  save $tmp/gbd_sd_`geo', replace
}

/* ENGLAND */
/* import the non-gbd prevalences */
import delimited $covidpub/covid/csv/uk_condition_sd.csv, clear

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)

/* create a new dataset and fill it with a manual reshape */
set obs 100
gen age = _n

foreach condition in sd_obese_1_2 sd_obese_3 sd_bp_high {
  foreach i in lower upper mean {
    gen `i'_`condition' = .
    forval age = 1/100 {
      qui sum `i' if condition == "`condition'" & inrange(`age', startage, endage)
      if `r(N)' > 0 {
        replace `i'_`condition' = `r(mean)' if age == `age'
      }
    }
  }
}
keep age *sd*

/* for each risk factor calculate the standard deviation */
foreach var in obese_1_2 obese_3 bp_high {

  /* take the log of each prevalence */
  gen `var'_log_diff1 = log10(upper_sd_`var') - log10(mean_sd_`var')
  gen `var'_log_diff2 =  log10(mean_sd_`var') - log10(lower_sd_`var')

  /* take the mean of the standard deviation */
  egen logsd_`var' = rmean(`var'_log_diff1 `var'_log_diff2)

  /* drop unneeded variabels */
  drop `var'_log_diff1 `var'_log_diff2
}
drop *lower* *upper* *mean*

/* merge in the gbd data */
merge 1:1 age using $tmp/gbd_sd_uk, nogen
drop if age < 18 | age > 99

/* append to uk prevalence file */
merge 1:1 age using $tmp/prev_uk_nhs_matched, nogen

/* save */
save $tmp/all_uk_sd, replace

/* get the copd data */
import delimited using $iec/covid/covid/csv/copd_mclean_rates.csv, clear

/* calculate the total population */
gen pop_total = pop_female + pop_male

/* calculate prevalence, upper, and lower bounds */
foreach i in mean lower upper {

  /* take the weighted average of male and female rates */
  gen copd_`i' = rate100k_male_`i'*(pop_male / pop_total) + rate100k_female_`i'*(pop_female / pop_total)

  /* convert the per 100k rate to a prevalence */
  replace copd_`i' = copd_`i' / 100000

}

/* take the log of each prevalence */
gen copd_log_diff1 = log10(copd_upper) - log10(copd_mean)
gen copd_log_diff2 =  log10(copd_mean) - log10(copd_lower)

/* take the mean of the standard deviation */
egen logsd_chronic_resp_dz = rmean(copd_log_diff1 copd_log_diff2)

/* save */
keep age logsd_chronic_resp_dz
save $tmp/uk_copd_sd, replace

/* merge in with the full dat */
use $tmp/all_uk_sd, clear 

/* merge into the final data */
merge 1:1 age using $tmp/uk_copd_sd, keepusing(logsd_chronic_resp_dz) nogen

/* keep only 18 - 100 year olds */
keep if inrange(age, 18, 100)

/* re-save */
save $tmp/all_uk_sd, replace

/* INDIA */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

/* count the sample size N at each age */
gen N = 1
collapse (sum) N [aw=wt], by(age)

/* merge in the prevalences */
merge 1:1 age using $tmp/prev_india, nogen

/* calculate standard deviation for each biomarker variable */
foreach var in $hr_biomarker_vars {
  gen  sd_`var' = sqrt((prev_`var' * (1 - prev_`var')) / N)
}
drop N

/* merge in the bgd sd */
merge 1:1 age using $tmp/gbd_sd_india, nogen

/* keep only 18 - 100 year olds */
keep if inrange(age, 18, 100)

/* save */
save $tmp/all_india_sd, replace
