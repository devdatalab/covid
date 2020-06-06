/* import hazard ratios from NHS study, fully adjusted model */
use $tmp/uk_nhs_hazard_ratios_flat_hr_fully_adj, clear

/* define reference group mortality -- 50--60 year olds */
global r = 355 / 3068883

/* rename hazard ratio vars for consistency */
foreach condition in $comorbid_vars {
  ren `condition'_hr_fully_adj hr_`condition'
}

/* calculate relative risk for each condition from hazard ratio */
foreach condition in $comorbid_vars {
  gen rr_`condition' = (1 - exp(hr_`condition' * ln(1 - ${r}))) / ${r}
}

/* calculate odds ratios from relative risk */
foreach condition in $comorbid_vars {
  gen or_`condition' = (rr_`condition' * (1 + ${r})) / (1 - rr_`condition' * ${r})
}

/* check we got it right by recalculating rr from or */
foreach condition in $comorbid_vars {
  gen rr2_`condition' = or_`condition' / (1 - $r + $r * or_`condition')
  gen diff = rr_`condition' / rr2_`condition'
  assert inrange(diff, .999, 1.001)
  drop diff
}
drop rr2*

/* check out the comparison */
foreach condition in $comorbid_vars {
  list or_`condition' rr_`condition' hr_`condition'
}


/* reshape to wide on different stats */
reshape long hr or rr, string i(v1) j(stat)
drop v1

/* round results to 3 digits */
foreach v in hr or rr {
  replace `v' = round(`v', .001)
  format `v' %6.3f
}

/* list results */
list
