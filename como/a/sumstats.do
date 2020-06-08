/* generate stats used in paper */
use $tmp/combined, clear

/* sample size */
count

/* age median and IQR */
sum age, d

/* risk factor severity */
foreach v in $age_vars male $hr_biomarker_vars {
  disp_nice "`v'"
  tab `v' [aw=wt], mi
}

/* open GBD data */
foreach country in india uk {
  use $health/gbd/gbd_nhs_conditions_`country'.dta, clear
  disp_nice "`country'"
  foreach v in $hr_gbd_vars {
    qui sum gbd_`v' if age == -90
    di %25s "`v': " %6.1f (`r(mean)' * 100) "%"
  }
}

/* self-report measures of liver and kidney disease for reference */
use $tmp/combined, clear
tab kidney_dz [aw=wt]
tab liver_dz [aw=wt]
