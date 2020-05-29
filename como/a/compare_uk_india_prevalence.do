use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

collapse (mean) diabetes bp_high resp_chronic, by(age)

merge 1:1 age using $tmp/uk_prevalences

label var diabetes "Diabetes (India)"
label var uk_prev_diabetes "Diabetes (UK)"
label var bp_high "BP High (India)"
label var uk_prev_hypertension "Hypertension (UK)"
label var resp_chronic "Chronic Respiratory (India)"
label var uk_prev_asthma "Asthma (UK)"
label var uk_prev_copd "COPD (UK)"

sort age

save $tmp/uk_india, replace
use $tmp/uk_india, clear

/* smooth the India conditions */
tsset age
foreach v in diabetes bp_high resp_chronic {
  replace `v' = (L2.`v' + L1.`v' + `v' + F1.`v' + F2.`v') / 5 if !mi(L2.`v') & !mi(F2.`v')
  replace `v' = (L1.`v' + `v' + F1.`v') / 3 if (mi(L2.`v') | mi(F2.`v')) & !mi(L1.`v') & !mi(F1.`v')
}

drop if age >= 90
sort age
twoway (line diabetes age, lwidth(medthick)) (line uk_prev_diabetes age, lwidth(medthick)), name(d, replace) yline(.028)
graphout diabetes_uk_india

twoway (line bp_high age, lwidth(medthick)) (line uk_prev_hypertension age, lwidth(medthick)), name(bp, replace) yline(.342)
graphout bp_uk_india

twoway (line resp_chronic age, lwidth(medthick)) (line uk_prev_asthma age, lwidth(medthick)) (line uk_prev_copd age, lwidth(medthick)), name(resp, replace) yline(.142 .041)
graphout resp_uk_india


