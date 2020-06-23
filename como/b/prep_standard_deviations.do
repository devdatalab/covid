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
  save $tmp/gbd_se_`geo', replace
}

/* ENGLAND */
/* import the non-gbd prevalences */
import delimited $covidpub/covid/csv/uk_condition_se.csv, clear

/* reshape wide on conditions */
replace condition = condition[_n-1] if mi(condition)

/* create a new dataset and fill it with a manual reshape */
set obs 100
gen age = _n

foreach condition in se_obese_1_2 se_obese_3 se_bp_high {
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
keep age *se*

/* for each risk factor calculate the standard deviation */
foreach var in obese_1_2 obese_3 bp_high {

  /* take the log of each prevalence */
  gen `var'_log_diff1 = log10(upper_se_`var') - log10(mean_se_`var')
  gen `var'_log_diff2 =  log10(mean_se_`var') - log10(lower_se_`var')

  /* take the mean of the standard deviation */
  egen logsd_`var' = rmean(`var'_log_diff1 `var'_log_diff2)

  /* drop unneeded variabels */
  drop `var'_log_diff1 `var'_log_diff2
}
drop *lower* *upper* *mean*

/* merge in the gbd data */
merge 1:1 age using $tmp/gbd_se_uk, nogen
drop if age < 18 | age > 99

/* append to uk prevalence file */
merge 1:1 age using $tmp/prev_uk_nhs_matched, nogen

/* save */
save $tmp/all_uk_sd, replace


/* INDIA */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

/* count the sample size N at each age */
gen N = 1
collapse (sum) N [aw=wt], by(age)
drop if age < 18 | age > 99

/* merge in the prevalences */
merge 1:1 age using $tmp/prev_india, nogen

/* calculate standard deviation for each biomarker variable */
foreach var in $hr_biomarker_vars {
  gen  sd_`var' = sqrt((prev_`var' * (1 - prev_`var')) / N)
}
drop N

/* merge in the bgd sd */
merge 1:1 age using $tmp/gbd_se_india, nogen

/* save */
save $tmp/all_india_sd, replace
