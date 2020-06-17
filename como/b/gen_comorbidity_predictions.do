/**********************/
/* POPULATION WEIGHTS */
/**********************/

/* open the population data */
use $pc11/pc11_pca_district_clean, clear

/* calculate total state and national population */
bys pc11_state_id: egen long state_pop = total(pc11_pca_tot_p)
egen long national_pop = total(pc11_pca_tot_p)

/* create state and district weights */
gen swt = pc11_pca_tot_p / state_pop
label var swt "district weight for state-level aggregation"
gen dwt = pc11_pca_tot_p / national_pop
label var dwt "district weight for national aggregation"

/* save as a temporary file */
keep pc11_state_id pc11_district_id pc11_pca_tot_p swt dwt
save $tmp/pc11_popweights, replace

/************************/
/* COMORBIDITY MEASURES */
/************************/

/* open the full dataset */
use $health/dlhs/data/dlhs_ahs_merged, clear

/* label the diagnosed_for and symptoms variables */
label var diagnosed_for "self-reported diagnosis in the last 1 year"
label var symptoms_pertaining_illness "self-reported symptoms of chronic illness in last 1 year"

/* generate age bins */
gen age18_40 = 0
replace age18_40 = 1 if (age >= 18 & age < 40)

gen age40_50 = 0
replace age40_50 = 1 if (age >= 40 & age < 50)

gen age50_60 = 0
replace age50_60 = 1 if (age >= 50 & age < 60)

gen age60_70 = 0
replace age60_70 = 1 if (age >= 60 & age < 70)

gen age70_80 = 0
replace age70_80 = 1 if (age >= 70 & age < 80)

gen age80_ = 0
replace age80_ = 1 if (age >= 80)

/* sex */
gen female = 0
replace female = 1 if sex == 2
replace female = . if (mi(sex) | sex == 3)

gen male = 0
replace male = 1 if sex == 1
replace male =. if (mi(sex) |sex == 3)

/* BMI */
/* convert height to meters */
gen height = length_height_cm*.01
label var height "height in meters"

/* calculate bmi */
gen bmi = weight_in_kg / (height^2)

/* replace with missing for pregnant women- we can't interpret BMI for them */
replace bmi = . if pregnant == 1
label var bmi "Body Mass Index kg/m^2"

/* replace extreme outliers with missing values */
replace bmi = . if bmi >= 100 
replace bmi = . if bmi < 10

/* get bmi categories used in UK paper */
gen bmi_not_obese = 0 if !mi(bmi)
replace bmi_not_obese = 1 if (bmi < 30)
label var bmi_not_obese "not obese, bmi < 30"

gen bmi_obeseI = 0 if !mi(bmi)
replace bmi_obeseI = 1 if (bmi >= 30 & bmi < 35)
label var bmi_obeseI "obese class I, bmi 30-<35"

gen bmi_obeseII = 0 if !mi(bmi)
replace bmi_obeseII = 1 if (bmi >= 35 & bmi < 40)
label var bmi_obeseII "obese class II, bmi 35-<40"

gen bmi_obeseIII = 0 if !mi(bmi)
replace bmi_obeseIII = 1 if (bmi >= 40)
label var bmi_obeseIII "obese class III, bmi >=40"

/* create obesity classes to match the NHS data */
gen obesity_class_1_2 = 0 if !mi(bmi)
replace obesity_class_1_2 = 1 if (bmi >= 30 & bmi < 40)
label var obesity_class_1_2 "obesity classes 1 and 2"

gen obesity_class_3 = 0 if !mi(bmi)
replace obesity_class_3 = 1 if (bmi >= 40)
label var obesity_class_3 "obesity class 3"

/* create additional WHO-defined BMI categories */
gen bmi_underweight_severe = 0 if !mi(bmi)
replace bmi_underweight_severe = 1 if bmi < 16 & !mi(bmi)
label var bmi_underweight_severe "WHO-defined severe underweight bmi"

gen bmi_underweight_moderate = 0 if !mi(bmi)
replace bmi_underweight_moderate = 1 if (bmi >= 16 & bmi < 17) & !mi(bmi)
label var bmi_underweight_moderate "WHO-defined moderate underweight bmi"

gen bmi_underweight_mild = 0 if !mi(bmi)
replace bmi_underweight_mild = 1 if (bmi >= 17 & bmi < 18.5) & !mi(bmi)
label var bmi_underweight_mild "WHO-defined mild underweight bmi"

gen bmi_normal = 0 if !mi(bmi)
replace bmi_normal = 1 if (bmi >= 18.5 & bmi < 25) & !mi(bmi)
label var bmi_normal "WHO-defined normal bmi"

gen bmi_preobese = 0 if !mi(bmi)
replace bmi_preobese = 1 if (bmi >= 25 & bmi < 30) & !mi(bmi)
label var bmi_preobese "WHO-defined preobese bmi"

/* Blood Pressure */
/* take the average of two systolic measurements */
gen bp_systolic = (bp_systolic_1_reading + bp_systolic_2_reading) / 2
label var bp_systolic "systolic BP taken as average of two measures"

/* take the average of two diastolic measurements */
gen bp_diastolic = (bp_diastolic_1_reading + bp_diastolic_2_reading) / 2
label var bp_diastolic "Diastolic BP taken as average of two measures"

/* define high blood pressure categories based on NHS paper */
/* normal */
gen bp_normal = 0
replace bp_normal = 1 if bp_systolic < 120 & bp_diastolic < 80
replace bp_normal = . if mi(bp_systolic) | mi(bp_diastolic)
replace bp_normal = . if pregnant == 1
label var bp_normal "systolic BP <120 mm Hg and diastolic BP < 80 mm Hg"

/* elevated */
gen bp_elevated = 0
replace bp_elevated = 1 if (bp_systolic >= 120 & bp_systolic < 130) & (bp_diastolic < 80)
replace bp_elevated = . if mi(bp_systolic) | mi(bp_diastolic)
replace bp_elevated = . if pregnant == 1
label var bp_elevated "systolic BP 120-129 and BP diastolic < 80"

/* high stage 1 */
gen bp_high_stage1 = 0
replace bp_high_stage1 = 1 if (bp_systolic >= 130 & bp_systolic < 140) & (bp_diastolic >= 80 & bp_diastolic < 90)
replace bp_high_stage1 = . if mi(bp_systolic) | mi(bp_diastolic)
replace bp_high_stage1 = . if pregnant == 1
label var bp_high_stage1 "systolic BP 130-139 mm Hg and diastolic BP 80-89"

/* high stage 2 */
gen bp_high_stage2 = 0
replace bp_high_stage2 = 1 if (bp_systolic >= 140) | (bp_diastolic >= 90)
replace bp_high_stage2 = . if mi(bp_systolic) | mi(bp_diastolic)
replace bp_high_stage2 = . if pregnant == 1
label var bp_high_stage2 "systolic BP >= 140 mm Hg or diastolic BP >= 90 mm Hg"

/* self-reported hypertension */
/* if data is from AHS CAB-only sample, keep as missing because there was no HH module asked */
gen hypertension_diagnosis = 0 if sample != 1
replace hypertension_diagnosis = 1 if diagnosed_for == 2
label var hypertension_diagnosis "self-reported diagnosis of hypertension"

/* just biomarker BP high stage 2 definition of hypertension */
gen hypertension_biomarker = bp_high_stage2
label var hypertension_biomarker "systolic BP >= 140 mm Hg or diastolic BP >= 90 mm Hg"

/* self-reported hypertension + BP high stage 2 */
gen hypertension_both = 0
replace hypertension_both = 1 if (hypertension_biomarker == 1 | hypertension_diagnosis == 1)
label var hypertension_both "self-reported hypertension and/or measured BP high stage 2"

/* create the inverse of hypertension_both */
gen hypertension_both_not = 1 - hypertension_both 
label var hypertension_both_not "normal blood pressure as defined as not hypertension_both"

/* create the inverse of hypertension_biomarker */
gen hypertension_biomarker_not = 1 - hypertension_biomarker
label var hypertension_biomarker_not "normal blood pressure as defined as not hypertension_biomarker"

/* controlled hypertension is defined as those diagnosed with BP marker below threshold */
gen hypertension_contr = hypertension_diagnosis
replace hypertension_contr = 0 if hypertension_biomarker == 1
label var hypertension_contr "hypertension diagnosis but normal BP reading"

/* Respiratory Disease */
gen resp_illness = 0 if sample != 1
replace resp_illness = 1 if diagnosed_for == 7
label var resp_illness "self-reported asthma or chronic respiratory failure"

/* get respiratory symptoms */
gen resp_symptoms = 0 if sample != 1
replace resp_symptoms = 1 if symptoms_pertaining_illness == 1
label var resp_symptoms "self-reported symptoms of respiratory illness"

/* get acute respiratory symptoms */
gen resp_acute = 0 if sample != 1
replace resp_acute = 1 if illness_type == 3
label var resp_acute "self-reported respiratory symptoms in the past 15 days"

/* ALL reports of chronic respiratory illness */
gen resp_chronic = 0 if sample != 1
replace resp_chronic = 1 if resp_illness == 1 | resp_symptoms == 1
label var resp_chronic "self-reported diagnosis or symptoms of respiratory illness"

/* Chronic heart disease */
gen cardio_illness = 0 if sample != 1
replace cardio_illness = 1 if diagnosed_for == 3 | diagnosed_for == 4 | diagnosed_for == 26
label var cardio_illness "self-reported diagnosis of chronic heart disease"

/* get cardiovascular system symptoms */
gen cardio_symptoms = 0 if sample != 1
replace cardio_symptoms = 1 if symptoms_pertaining_illness == 2
label var cardio_symptoms "self-reported symptoms of cardiovascular disease"

/* ALL reports of chronic heart disease */
gen chronic_heart_dz = 0 if sample != 1
replace chronic_heart_dz = 1 if (cardio_illness == 1 | cardio_symptoms == 1)
label var chronic_heart_dz "self-reported diagnosis or symptoms of heart disease"

/* Diabetes */
gen diabetes_biomarker = 0 if !mi(fasting_blood_glucose_mg_dl)

/* standard WHO definition of diabetes is >=126mg/dL if fasting and >=200 if not */
replace diabetes_biomarker = 1 if (fasting_blood_glucose_mg_dl >= 126 & fasting_blood_glucose == 2) | (fasting_blood_glucose_mg_dl >= 200 & fasting_blood_glucose == 1)

/* assume that people with a glucose measure but missing fasting data are fasting */
replace diabetes_biomarker = 1 if (fasting_blood_glucose_mg_dl >= 126 & !mi(fasting_blood_glucose_mg_dl)) & mi(fasting_blood_glucose)

/* the threshold is not well established for pregnant women, set their values to missing */
replace diabetes_biomarker = . if pregnant == 1
label var diabetes_biomarker "blood sugar >126mg/dL if fasting, >200mg/dL if not"

/* get diabetes that are self-reported */
gen diabetes_diagnosis = 0 if !mi(diagnosed_for)
replace diabetes_diagnosis = 1 if diagnosed_for == 1
label var diabetes_diagnosis "self-reported diagnosis of diabetes in the last year"

/* combined diabetes measure */
gen diabetes_both = 1 if diabetes_biomarker == 1 | diabetes_diagnosis == 1
replace diabetes_both = 0 if mi(diabetes_both)
label var diabetes_both "biomarker or self-reported diabetes diagnosis"

/* controlled diabetes is defined as those diagnosed with diabetes but glucose below threshold */
gen diabetes_contr = diabetes_diagnosis
replace diabetes_contr = 0 if diabetes_biomarker == 1
label var diabetes_contr "diabetes diagnosis but normal glucose reading"

/* Cancer - non-haematological */
gen cancer_non_haem = 0 if sample != 1
/* respiratory system, gastrointestinal system, genitourinary system, breast, tumor (any type), skin cancer */
replace cancer_non_haem = 1 if (diagnosed_for == 11 | diagnosed_for == 12 | diagnosed_for == 13 | diagnosed_for == 14 | diagnosed_for == 27 | diagnosed_for == 29)
label var cancer_non_haem "self-reported non haematological cancer"

/* Haematological malignanies */
gen haem_malig = 0 if sample != 1 
replace haem_malig = 1 if (diagnosed_for == 28)
label var haem_malig "self-reported blood cancer/leukemia"

/* Liver disease */
gen liver_dz = 0 if sample != 1
replace liver_dz = 1 if diagnosed_for == 18
label var liver_dz "self-reported chronic liver disease"

/* Stroke */
gen stroke = 0 if sample != 1
replace stroke = 1 if diagnosed_for == 5
label var stroke "self-reported stroke cerebro vascular accident"

/* Kidney disease */
gen kidney_dz = 0 if sample != 1
replace kidney_dz = 1 if (diagnosed_for == 15 | diagnosed_for == 16)
label var kidney_dz "self-reported renal stones or chronic renal disease"

/* Autoimmune disease */
gen autoimmune_dz = 0 if sample != 1
replace autoimmune_dz = 1 if (diagnosed_for == 19 | diagnosed_for == 20)
label var autoimmune_dz "self-reported psoriasis or rheumatoid arthritis"

/* keep only identifying information and comorbidity variables */
keep uid pc11* psu htype rcvid supid tsend tsstart person_index hh* *wt survey rural_urban stratum psu_id ahs_house_unit house_hold_no date_survey age* male female bmi* height weight_in_kg bp* hypertension* resp* cardio_symptoms diabetes* *haem* *_dz stroke diagnosed_for fasting* survey sample

/* create a combined weight variable */
/* - assume all AHS weights are 1 (since it's self-weighting) */
/* - use state weights, not district weights, since we care about national representativeness */
replace dhhwt = 1 if mi(dhhwt)
capdrop wt
gen hhwt = dhhwt

/* merge in population weights */
merge m:1 pc11_state_id pc11_district_id using $tmp/pc11_popweights, keep(match master)
drop _merge

/* calculate final weight which is household * district */
gen wt = hhwt * dwt
label var wt "household x district weight for national aggregation"

/* save the full dataset */
save $health/dlhs/data/dlhs_ahs_covid_comorbidities_full, replace

/* drop if missing key values from CAB survey - we want to only use observations that have these measureable values */
drop if mi(hypertension_biomarker) | mi(diabetes_biomarker) | mi(bmi)

/* drop if missing all self-reported illness, i.e. only the CAB section was asked */
drop if sample == 1

/* create a single age bin variable from the many binary variables */
gen age_bin = ""
foreach i in age18_40 age40_50 age50_60 age60_70 age70_80 age80_ {
  replace age_bin = "`i'" if `i' != 0 
}

/* map DLHS/AHS conditions to the ones we have hazard ratios for in the NHS paper */
/* note: following the NHS study, we use biomarker for this part, not diagnosis */
gen chronic_resp_dz = resp_chronic
gen cancer_non_haem_1 = cancer_non_haem
gen haem_malig_1 = haem_malig
gen stroke_dementia = stroke
gen bp_high = hypertension_biomarker
gen bp_not_high = hypertension_biomarker_not
gen diabetes_uncontr = diabetes_biomarker
gen hypertension_uncontr = hypertension_biomarker

/* UK prevalence categories force us to combine obese 1 & 2 */
gen obese_1_2 = bmi_obeseI | bmi_obeseII
gen obese_3   = bmi_obeseIII

label var chronic_resp_dz   "Chronic respiratory disease as matched to NHS"
label var diabetes_uncontr  "Diabetes as matched to NHS"
label var cancer_non_haem_1 "Non-Haem cancer as matched to NHS"
label var haem_malig_1      "Haematological cancer as matched to NHS"
label var stroke_dementia   "Stroke/dementia as matched to NHS"
label var bp_high           "Hypertension as matched to NHS"
label var bp_not_high       "No Hypertension as matched to NHS"
label var hypertension_uncontr "Hypertension according to BP reading"
label var diabetes_uncontr  "Diabetes according to glucose reading"
label var obese_1_2     "Obese (30 < BMI < 39.9)"
label var obese_3       "Obese (BMI > 40)"

/* save limited dataset with only comorbidity data */
compress
save $health/dlhs/data/dlhs_ahs_covid_comorbidities, replace







/*****************************************************************/
/* PN 6/16/2020 --- I believe everything below this is obsolete. */
/*****************************************************************/
exit
exit
exit


/* combine the risk factors with the DLHS/AHS */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

/* shrink by dropping string vars */
drop tsend tsstart date_survey

merge 1:1 uid using $tmp/individual_risk_factors_hr_full, gen(_m_full)
assert _m_full == 3
drop _m_full
merge 1:1 uid using $tmp/individual_risk_factors_hr_age_sex, gen(_m_agesex)
assert _m_agesex == 3
drop _m_agesex

/* bring in continuous age factors */
winsorize age 18 100, replace
merge m:1 age using $tmp/uk_age_predicted_hr, gen(_m_cts_age) keep(match master)
assert _m_cts_age == 3

/* limit to the 18-99 year old sample for the paper */
keep if inrange(age, 18, 99)

/* save micro dataset with NHS hazard ratios */
save $tmp/combined, replace
