use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

gen obese = bmi_obeseI | bmi_obeseII | bmi_obeseIII

collapse (mean) obese diabetes_both diabetes_uncontr bp_high chronic_resp_dz [aw=wt], by(age)

save $tmp/post_collapse, replace
use $tmp/post_collapse, clear

/* merge UK prevalences from various sources */
merge 1:1 age using $tmp/uk_prevalences, keep(match) nogen

/* merge India and UK GBD data */
merge 1:1 age using $health/gbd/gbd_nhs_conditions_uk, keep(match) nogen
drop *granular
drop *upper *lower
ren gbd_* gbd_uk_*
merge 1:1 age using $health/gbd/gbd_nhs_conditions_india, keep(match) nogen
drop *granular
drop *upper *lower
ren gbd_* gbd_india_*
ren gbd_india_uk_* gbd_uk_*

/* label india microdata vars */
label var diabetes_both "Diabetes (India)"
label var bp_high "Hypertension (India)"
label var chronic_resp_dz "Chronic Respiratory (India)"
label var obese "Obese (BMI >= 30, India)"

/* label UK summary report vars */
gen uk_prev_diabetes = uk_prev_diabetes_biomarker
gen uk_prev_hypertension = uk_prev_hypertension_biomarker
label var uk_prev_diabetes "Diabetes (UK)"
label var uk_prev_hypertension "Hypertension (UK)"
label var uk_prev_asthma "Asthma (UK)"
label var uk_prev_copd "COPD (UK)"
label var uk_prev_obese "Obese (BMI >= 30, UK)"

/* label GBD vars */
label var gbd_india_chronic_resp_dz "COPD (GBD-India)"
label var gbd_india_diabetes "Diabetes (GBD-India)"
label var gbd_india_asthma_ocs "Asthma (GBD-India)"
label var gbd_india_chronic_heart_dz "Heart Disease (GBD-India)"

label var gbd_uk_chronic_resp_dz "COPD (GBD-UK)"
label var gbd_uk_diabetes "Diabetes (GBD-UK)"
label var gbd_uk_asthma_ocs "Asthma (GBD-UK)"
label var gbd_uk_chronic_heart_dz "Heart Disease (GBD-UK)"

sort age

save $tmp/uk_india, replace
use $tmp/uk_india, clear

/* apply a smoother to the India microdata conditions */
tsset age
foreach v in diabetes_both diabetes_uncontr bp_high chronic_resp_dz {
  replace `v' = (L2.`v' + L1.`v' + `v' + F1.`v' + F2.`v') / 5 if !mi(L2.`v') & !mi(F2.`v')
  replace `v' = (L1.`v' + `v' + F1.`v') / 3 if (mi(L2.`v') | mi(F2.`v')) & !mi(L1.`v') & !mi(F1.`v')
}

sort age
keep if age < 80

/* biomarker comparisons only */
scp diabetes_both uk_prev_diabetes, name(diabetes) yline(.088)
scp bp_high uk_prev_hypertension, name(hypertension) yline(.342)
scp obese uk_prev_obese, name(obese) yline(.218)
graph combine diabetes hypertension obese, rows(2)
graphout biomarker_uk_india


scp gbd_uk_diabetes gbd_india_diabetes, name(gbd_diabetes)
