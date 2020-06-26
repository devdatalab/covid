/*************************************************************************************/
/* TEST: how much does interaction of comorbidities affect population relative risk? */

/* Note:

We can only do this for the biomarker conditions that we have in the
Indian data since we don't have microdata on the GBD variables. */

/*************************************************************************************/

/* open Indian comorbidity microdata */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear
keep wt age male $hr_biomarker_vars

/* merge primary hazard ratios */
merge m:1 age using $tmp/hr_full_cts

/* calculate the risk factor for each individual, multiplying the hazard ratio by
   an indicator for condition existence. */
gen prr_health = 1
foreach v in male $hr_biomarker_vars  {

  qui gen prr_`v' = `v' * hr_`v' + (1 - `v')
  qui replace prr_health = prr_health * prr_`v'
  qui sum prr_health [aw=wt]
  di %20s "`v': " %5.2f `r(mean)'
}

/* collapse combined health PRR to age-level using survey weights */
collapse (mean) male $hr_biomarker_vars prr_health [aw=wt], by(age)
ren prr_health prr_health_micro

/* now repeat the exercise using the aggregate data (which ignores interactions) */
merge 1:1 age using $tmp/hr_full_cts, nogen
gen prr_health_agg = 1
foreach v in male $hr_biomarker_vars {
  qui gen prr_`v' = `v' * hr_`v' + (1 - `v')
  qui replace prr_health_agg = prr_health_agg * prr_`v'
  qui sum prr_health_agg
  di "`v': " %5.2f `r(mean)'
}

gen gap = prr_health_micro / prr_health_agg
tsset age
replace gap = (L3.gap + L2.gap + L.gap + gap + F.gap + F2.gap + F3.gap) / 7 if !mi(L3.gap) & !mi(F3.gap)
keep if age <= 95

/* plot the two age-specific PRR distributions */
sort age
twoway ///
    (line prr_health_micro age, lwidth(medthick) lcolor(black)) ///
    (line prr_health_agg   age, lwidth(medthick) lcolor(lavender)), ///
    ytitle("Aggregate Contribution to Mortality from Risk Factors") xtitle("Age") ///
    legend(lab(1 "Microdata") lab(2 "Aggregate Data") ring(0) pos(5) cols(1) size(small) symxsize(5) bm(tiny) region(lcolor(black))) ///
    ylabel(1(.5)2.5) 
graphout prr_health_joint

line gap age if age < 98, lwidth(medthick) ylabel(1 1.05 1.1 1.15) ///
    xtitle("Age") ytitle("Increased population relative risk" "from comorbidity correlation")
graphout prr_ratio_micro, pdf
