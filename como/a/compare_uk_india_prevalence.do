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

drop if age > 90

twoway (scatter diabetes age) (scatter uk_prev_diabetes age), name(d, replace) yline(.028)
graphout diabetes_uk_india

twoway (scatter bp_high age) (scatter uk_prev_hypertension age), name(bp, replace) yline(.342)
graphout bp_uk_india

twoway (scatter resp_chronic age) (scatter uk_prev_asthma age) (scatter uk_prev_copd age), name(resp, replace) yline(.142 .041)
graphout resp_uk_india


