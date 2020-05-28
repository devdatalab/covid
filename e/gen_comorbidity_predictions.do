global comorbid_vars age18_40 age40_50 age50_60 age60_70 age70_80 age80_ female male bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global comorbid_vars_no_age_sex bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 


/***************************/
/* Merge DLHS and AHS Data */
/***************************/
/* open the dlhs data */
use $health/dlhs/dlhs_cab, clear

/* rename variables to align with ahs */
ren hv05 sex
ren hv06 usual_residance
ren age_test age
ren hv82 weight_in_kg
ren hv85 length_height_cm
ren hv93a bp_systolic_1_reading
ren hv93b bp_systolic_2_reading
ren hv94a bp_diastolic_1_reading
ren hv94b bp_diastolic_2_reading
ren hv19 illness_type
ren hv21 symptoms_pertaining_illness
ren hv23 diagnosed_for

/* mark as dlhs */
gen survey = 1

/* append the ahs data */
append using $health/ahs/ahs_cab

/* mark as ahs */
replace survey = 2 if mi(survey)

/* label the survey indicator */
cap label define dlhs_ahs 1 "dlhs" 2 "ahs"
label values survey dlhs_ahs

/************************/
/* COMORBIDITY MEASURES */
/************************/

/* drop if not a usual resident */
keep if usual_residance == 1

/* drop missing age and those under 18 */
drop if mi(age)
drop if age < 18

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
label var bmi "Body Mass Index kg/m^2"

/* replace extreme outliers with missing values: q. should we do this based on physical values or stats? */
replace bmi = . if bmi >= 100 
replace bmi = . if bmi <10

/* get bmi categories */
gen bmi_not_obese = 0
replace bmi_not_obese = 1 if (bmi < 30)
replace bmi_not_obese = . if mi(bmi)
label var bmi_not_obese "not obese, bmi < 30"

gen bmi_obeseI = 0
replace bmi_obeseI = 1 if (bmi >= 30 & bmi < 35)
replace bmi_obeseI = . if mi(bmi)
label var bmi_obeseI "obese class I, bmi 30-<35"

gen bmi_obeseII = 0
replace bmi_obeseII = 1 if (bmi >= 35 & bmi < 40)
replace bmi_obeseII = . if mi(bmi)
label var bmi_obeseII "obese class II, bmi 35-<40"

gen bmi_obeseIII = 0
replace bmi_obeseIII = 1 if (bmi >= 40)
replace bmi_obeseIII = . if mi(bmi)
label var bmi_obeseIII "obese class III, bmi >=40"

/* Blood Pressure */
/* take the average of two systolic measurements */
gen bp_systolic = (bp_systolic_1_reading + bp_systolic_2_reading) / 2
label var bp_systolic "systolic BP taken as average of two measures"

/* take the average of two systolic measurements */
gen bp_diastolic = (bp_diastolic_1_reading + bp_diastolic_2_reading) / 2
label var bp_diastolic "Diastolic BP taken as average of two measures"

/* define high blood pressure categories based on NHS paper */

/* normal */
gen bp_normal = 0
replace bp_normal = 1 if bp_systolic < 120 & bp_diastolic < 80
replace bp_normal = . if mi(bp_systolic) | mi(bp_diastolic)
label var bp_normal "systolic BP <120 mm Hg and diastolic BP < 80 mm Hg"

/* elevated */
gen bp_elevated = 0
replace bp_elevated = 1 if (bp_systolic >= 120 & bp_systolic <= 129) & (bp_diastolic < 80)
replace bp_elevated = . if mi(bp_systolic) | mi(bp_diastolic)
label var bp_elevated "systolic BP 120-129 and BP diastolic < 80"

/* high stage 1 */
gen bp_high_stage1 = 0
replace bp_high_stage1 = 1 if (bp_systolic >= 130 & bp_systolic <= 139) & (bp_diastolic >= 80 & bp_diastolic <=89)
replace bp_high_stage1 = . if mi(bp_systolic) | mi(bp_diastolic)
label var bp_high_stage1 "systolic BP 130-139 mm Hg and diastolic BP 80-89"

/* high stage 2 */
gen bp_high_stage2 = 0
replace bp_high_stage2 = 1 if (bp_systolic >= 140) | (bp_diastolic >= 90)
replace bp_high_stage2 = . if mi(bp_systolic) | mi(bp_diastolic)
label var bp_high_stage2 "systolic BP >= 140 mm Hg or diastolic BP >= 90 mm Hg"

/* self-reported hypertension */
label var diagnosed_for "self-reported diagnosis in the last 1 year"

gen bp_hypertension = 0
replace bp_hypertension = 1 if diagnosed_for == 2
label var bp_hypertension "self-reported diagnosis of hypertension"

/* self-reported hypertension + BP high stage 2 */
gen bp_high = 0
replace bp_high = 1 if (bp_high_stage2 == 1 | bp_hypertension == 1)
label var bp_high "self-reported hypertension and/or measured BP high stage 2"

/* create the inverse of bp_high */
gen bp_not_high = 1 if bp_high == 0
replace bp_not_high = 0 if bp_high == 1
label var bp_high "normal blood pressure as defined as not bp_high"

/* Respiratory Disease */
gen resp_illness = 0
replace resp_illness = 1 if diagnosed_for == 7
label var resp_illness "self-reported asthma or chronic respiratory failure"

/* get respiratory symptoms */
gen resp_symptoms = 0
replace resp_symptoms = 1 if symptoms_pertaining_illness == 1
label var resp_symptoms "self-reported symptoms of respiratory illness"

/* get acute respiratory symptoms */
gen resp_acute = 0
replace resp_acute = 1 if illness_type == 3
label var resp_acute "self-reported respiratory symptoms in the past 15 days"

/* get ANY respiratory issue */
gen resp_chronic = 0
replace resp_chronic = 1 if resp_illness == 1 | resp_symptoms == 1 
label var resp_chronic "self-reported diagnosis or symptoms of respiratory illness"

/* Chronic heart disease */
gen chronic_heart_dz = 0
replace chronic_heart_dz = 1 if diagnosed_for == 3
label var chronic_heart_dz "self-reported chronic heart disease"

/* get cardiovascular system symptoms */
gen cardio_symptoms = 0
replace cardio_symptoms = 1 if symptoms_pertaining_illness == 2

/* Diabetes */
gen diabetes = 0

/* standard WHO definition of diabetes is >=126mg/dL if fasting and >=200 if not */
replace diabetes = 1 if (hv91a >= 126 & hv91 == 1) | (hv91a >= 200 & hv91 == 2 & !mi(hv91a)) | (fasting_blood_glucose_mg_dl > 126 & !mi(fasting_blood_glucose_mg_dl))
replace diabetes = . if (mi(hv91a) | mi(hv91)) & mi(fasting_blood_glucose_mg_dl)
label var diabetes "blood sugar >126mg/dL if fasting, >200mg/dL if not"

/* Cancer - non-haematological */
gen cancer_non_haem = 0
/* respiratory system, gastrointestinal system, genitourinary system, breast, tumor (any type), skin cancer */
replace cancer_non_haem = 1 if (diagnosed_for == 11 | diagnosed_for == 12 | diagnosed_for == 13 | diagnosed_for == 14 | diagnosed_for == 27 | diagnosed_for == 29)
label var cancer_non_haem "self-reported non haematological cancer"

/* Haematological malignanies */
gen haem_malig = 0
replace haem_malig = 1 if (diagnosed_for == 28)
label var haem_malig "self-reported blood cancer/leukemia"

/* Liver disease */
gen liver_dz = 0
replace liver_dz = 1 if diagnosed_for == 18
label var liver_dz "self-reported chronic liver disease"

/* Stroke */
gen stroke = 0
replace stroke = 1 if diagnosed_for == 5
label var stroke "self-reported stroke cerebro vascular accident"

/* Kidney disease */
gen kidney_dz = 0
replace kidney_dz = 1 if (diagnosed_for == 15 | diagnosed_for == 16)
label var kidney_dz "self-reported renal stones or chronic renal disease"

/* Autoimmune disease */
gen autoimmune_dz = 0
replace autoimmune_dz = 1 if (diagnosed_for == 19 | diagnosed_for == 20)
label var autoimmune_dz "self-reported psoriasis or rheumatoid arthritis"

/* keep only identifying information and comorbidity variables */
keep pc11* psu prim_key* htype rcvid supid tsend tsstart person_index hh* *wt survey rural_urban stratum psu_id ahs_house_unit  house_hold_no date_survey age* male female bmi* height weight_in_kg bp* resp* cardio_symptoms diabetes *haem* *_dz stroke diagnosed_for survey ahs_merge

/* drop if missing key values from CAB survey */
drop if mi(bp_systolic) | mi(bp_diastolic) | mi(age) | (mi(female) & mi(male)) | mi(diabetes) | mi(bmi)

/* create a combined weight variable */
/* - assume all AHS weights are 1 (since it's self-weighting) */
/* - use state weights, not district weights, since we care about national representativeness */
/* FIX: need to scale dhhwt by district pop / national pop to make nationally representative
         (https://devdatalab.slack.com/archives/C012P55U163/p1590344336022400?thread_ts=1590343170.011200&cid=C012P55U163)*/
replace dhhwt = 1 if mi(dhhwt)
capdrop wt
gen wt = dhhwt

/* create a single age bin variable from the many binary variables */
gen age_bin = ""
foreach i in age18_40 age40_50 age50_60 age60_70 age70_80 age80_ {
  replace age_bin = "`i'" if `i' != 0 
}

/* drop duplicates and create a unique identifier */
duplicates drop
gen uid = _n

/* save limited dataset with only comorbidity data */
compress
save $health/dlhs/data/dlhs_ahs_covid_comorbidities, replace

/***************************/
/* Apply the UK Weightings */
/***************************/

/* define program to apply HR values */
cap prog drop apply_hr_to_comorbidities
prog def apply_hr_to_comorbidities
  syntax, hr(string)

  /* define the matches we want - these are the subjective ones.
     use NHS name for the local name and point to the AHS/DLHS var */
  local chronic_resp_dz resp_chronic
  local diabetes_uncontr diabetes
  local cancer_non_haem_1 cancer_non_haem
  local haem_malig_1 haem_malig
  local stroke_dementia stroke

  /* prep the uk HR data */
  import delimited $covidpub/covid/csv/uk_nhs_hazard_ratios.csv, clear

  /* label variables */
  lab var hr_age_sex "hazard ratio age-sex adjusted"
  lab var hr_age_sex_low "hazard ratio age-sex adjusted lower CI"
  lab var hr_age_sex_up "hazard ratio age-sex adjusted upper CI"
  lab var hr_full "hazard ratio fully adjusted"
  lab var hr_full_low "hazard ratio fully adjusted lower CI"
  lab var hr_full_up "hazard ratio fully adjusted upper CI"
  lab var hr_full_ec "hazard ratio fully adjusted early censoring"
  lab var hr_full_low_ec "hazard ratio fully adjusted early censoring lower CI"
  lab var hr_full_up_ec "hazard ratio fully adjusted early censoring upper CI"

  /* keep only the variables we need */
  gen ok = 0

  /* mark each variable we want to keep */
  foreach var in $comorbid_vars {
    replace ok = 1 if variable == "`var'"
  }
  keep if ok == 1
  drop ok

  /* save as dta file */
  save $tmp/uk_nhs_hazard_ratios, replace

  /* call a short python funciton to flatten our selected HR value into an array */
  cd $ddl/covid
  shell python -c "from e.flatten_hr_data import flatten_hr_data; flatten_hr_data('`hr'', '$tmp/uk_nhs_hazard_ratios.dta', '$tmp/uk_nhs_hazard_ratios_flat_`hr'.csv')"

  /* read in the csv and save as a stata file */
  import delimited $tmp/uk_nhs_hazard_ratios_flat_`hr'.csv, clear

  /* get list of all variables */
  qui lookfor bmi_obesei
  local bmi_vars = "`r(varlist)'"

  /* correct any misimported variables that have true names as values */
  foreach v in `bmi_vars'  {
    local x : variable label `v'
    ren `v' `x'
  }

  /* save as dta */
  save $tmp/uk_nhs_hazard_ratios_flat_`hr', replace

  /* open the india data */
  use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

  /* rename variables according to how we want to match to the NHS HR */
  ren `chronic_resp_dz' chronic_resp_dz
  ren `diabetes_uncontr' diabetes_uncontr
  ren `cancer_non_haem_1' cancer_non_haem_1
  ren `haem_malig_1' haem_malig_1
  ren `stroke_dementia' stroke_dementia

  /* create a dummy index to merge in the HR values */
  gen v1 = 0

  /* merge in the HR values */
  merge m:1 v1 using $tmp/uk_nhs_hazard_ratios_flat_`hr'
  drop _merge v1

  /* save a temporary file with the combined India conditions and the UK HRs */
  save $tmp/conditions_`hr', replace
    
  /* for each condition, store the risk adjustment factor according to whether
     the condition is present. */
  /* slightly confusing nomenclature:
     - diabetes_hr_full is the hazard ratio from the literature
     - this loop creates hr_full_diabetes, which is the individual-specific multiplier,
       which will be 1 if the individual does not have the condition, or the HR if they
       do have it.
  */
  foreach condition in $comorbid_vars {
    gen `hr'_`condition' = `condition'_`hr' if `condition' == 1
    replace `hr'_`condition' = 1 if `condition' == 0
    drop `condition'_`hr'
  }

  /* can we save only the risk factors and the individual identifier?
     Is there an individual identifier? */
  keep uid `hr'_*
  save $tmp/individual_risk_factors_`hr', replace
end

/* call the function for fully adjusted HR */
apply_hr_to_comorbidities, hr(hr_full)

/* call the function for only age and sex adjusted HR */
apply_hr_to_comorbidities, hr(hr_age_sex)

/* convert continuous age HRs to stata */
import delimited $covidpub/covid/csv/uk_age_predicted_or.csv, clear
ren or_simple hr_age_cts_simple
ren or_full hr_age_cts_full
replace hr_age_cts_simple = exp(hr_age_cts_simple)
replace hr_age_cts_full = exp(hr_age_cts_full)
save $tmp/uk_age_predicted_or, replace

/* combine the risk factors with the DLHS/AHS */
use $health/dlhs/data/dlhs_ahs_covid_comorbidities, clear

/* shrink by dropping string vars */
drop prim_key tsend tsstart date_survey

merge 1:1 uid using $tmp/individual_risk_factors_hr_full, gen(_m_full)
assert _m_full == 3
drop _m_full
merge 1:1 uid using $tmp/individual_risk_factors_hr_age_sex, gen(_m_agesex)
assert _m_agesex == 3
drop _m_agesex

/* bring in continuous age factors */
winsorize age 18 100, replace
merge m:1 age using $tmp/uk_age_predicted_or, gen(_m_cts_age) keep(match master)
assert _m_cts_age == 3

gen x = uniform()
sort x
drop x
list age hr_*_age40_50 age40_50 hr_age_cts_full hr_age_cts_simple in 1/20
list age hr_*_age60_70 age60_70 hr_age_cts_full hr_age_cts_simple in 1/200

save $tmp/combined, replace
use $tmp/combined, clear

/* for each person, calculate relative mortality risk by combining HRs from all conditions */

/* note that each person appears twice in the data, with identical
conditions but different risk adjustments.  which is why e.g. diabetes
can take on 3 different values instead of 2. */

/* risk_factor is the heightened probability of mortality relative to the reference group
  for this individual. Note that this is a probability multiplier, *not* a multiplier of
  relative risk, odds ratio, or hazard ratio.

  FIX: However, it is calculated by treating the HR as an OR-- this is inconsequential but
       we should do the conversion above anyway just to be precise. */

/* create separate risk factors for each different assumption set */
foreach v in simple full simple_cts full_cts conditions_only age_weird {
  gen risk_factor_`v' = 1
}

/* 1. fully adjusted model, binned ages */
foreach condition in $comorbid_vars {
  replace risk_factor_full = risk_factor_full * hr_full_`condition'
}

/* 2. age-sex only, binned ages */
foreach condition in age18_40 age40_50 age50_60 age60_70 age70_80 age80_ male female {
  replace risk_factor_simple = risk_factor_simple * hr_age_sex_`condition'
}

/* 3. fully adjusted, continuous age */
/* first do the non-age conditions */
foreach condition in $comorbid_vars_no_age_sex {
  replace risk_factor_full_cts = risk_factor_full_cts * hr_full_`condition'
}

/* now do the continuous age adjustment */
replace risk_factor_full_cts = risk_factor_full_cts * hr_age_cts_full

/* 4. age-sex only, continuous age */
/* adjust gender */
replace risk_factor_simple_cts = risk_factor_simple_cts * hr_age_sex_male * hr_age_sex_female

/* adjust continuous age */
replace risk_factor_simple_cts = risk_factor_simple_cts * hr_age_cts_simple

/* 5. experimental: risk factor from comorbid conditions only */
foreach condition in $comorbid_vars_no_age_sex {
  replace risk_factor_conditions_only = risk_factor_conditions_only * hr_full_`condition'
}

/* 6. experimental: use fully adjusted age model, but adjust for
      age-sex only (to see how much the conditions actually change the
      result) */
replace risk_factor_age_weird = risk_factor_age_weird * hr_age_cts_full * hr_full_male * hr_full_female

/* save full dat set */
save $tmp/tmp_hr_data, replace



/* paul stopped here -- the rest needs to be updated with the risk ratios */
exit

/* create sample size counter */
gen N = 1

/* Collapse to age/state groups */
collapse (sum) N (mean) risk_total risk_age_sex, by(pc11_state_id pc11_state_name age_bin hr)

/* get the risk for all comorbidities with the fully adjusted HR */
gen r_comorbid_adj = risk_total if hr == "hr_full"
replace r_comorbid_adj = 0 if mi(r_comorbid_adj)

/* get the risk for age and sex with the fully adjusted HR */
gen r_age_sex_adj = risk_age_sex if hr =="hr_full"
replace r_age_sex_adj= 0 if mi(r_age_sex_adj)

/* get the risk for age and sex with just age and sex adjusted HR */
gen r_age_sex_unadj = risk_age_sex if hr == "hr_age_sex"
replace r_age_sex_unadj = 0 if mi(r_age_sex_unadj)

/* collpse across HR values */
collapse (sum) r_comorbid_adj r_age_sex_adj r_age_sex_unadj, by(pc11_state_name pc11_state_id age_bin N)

/* label variables */
label var r_comorbid_adj "risk for all comorbidities with fully adjusted HR"
label var r_age_sex_adj "risk for age and sex with fully adjusted HR"
label var r_age_sex_unadj "risk for age and sex with only age-sex adjusted HR"

/* save data set */
save $health/dlhs/data/comorbid_risk_estimates, replace
