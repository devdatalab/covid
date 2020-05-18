/* Structure DLHS data */

/* initiate empty files for each  */
cap mkdir $tmp/dlhs
clear
save $tmp/dlhs/dlhs_BIRTH, emptyok replace
save $tmp/dlhs/dlhs_cab, emptyok replace
save $tmp/dlhs/dlhs_HOUSEHOLD, emptyok replace
save $tmp/dlhs/dlhs_IMMU, emptyok replace
save $tmp/dlhs/dlhs_marriage, emptyok replace
save $tmp/dlhs/dlhs_person, emptyok replace
save $tmp/dlhs/dlhs_village, emptyok replace
save $tmp/dlhs/dlhs_WOMAN, emptyok replace

/* combine state data for each file type */
local statelist Andaman_Nicobar AndhraPradesh ArunachalPradesh Chandigarh GOA Haryana HimachalPradesh Karnataka Kerala Maharashtra Manipur Meghalaya Mizoram Nagaland Puducherry Punjab Sikkim TamilNadu Telangana Tripura WestBengal

/* cycle through all states with dlhs data */
foreach state in `statelist' {

  /* get the list of files in the state folder */
  local filelist: dir "$health/dlhs/raw/`state'" files "*.dta"

  /* cycle through the data files for this state */
  foreach file in `filelist' {

    /* extract the name of this file */
    tokenize "`file'" , parse("_")
    local var = "`3'"
    
    /* open the file */
    use $health/dlhs/raw/`state'/`file', clear

    /* save the state name */
    gen state_name = "`state'"
    replace state_name = lower(state_name)

    /* append to the full file */
    append using $tmp/dlhs/dlhs_`var'

    /* resave full file */
    save $tmp/dlhs/dlhs_`var', replace
  }
}


/* open the new data files, clean and save */
use $tmp/dlhs/dlhs_cab, clear

/* clean state names */
replace state_name = subinstr(state_name, "pradesh", " pradesh", .)
replace state_name = "andaman nicobar islands" if state_name == "andaman_nicobar"
replace state_name = "tamil nadu" if state_name == "tamilnadu"

/* rename state name to match pc11 */
// ren state_name pc11_state_name

/* merge in pc11 district identifiers */
// merge m:1 pc11_state_name dist using $health/dlhs/dlhs4_district_key, keep(master) keepusing(pc11_district_id)
//drop _merge


/************************/
/* COMORBIDITY MEASURES */
/************************/
/* drop if the CAB module was not asked of this individual */
drop if mi(q77_intro)

/* AGE - for now use age_test var which is almost always the same as the roster age, not the same as the CAB age */
ren age_test age

/* drop all people missing age */
drop if mi(age)

/* BMI */
/* convert height to meters */
gen height = hv85*.01
label var height "height in meters"

/* label weight */
gen weight = hv82
label var weight "weight in kg"

/* calculate bmi */
gen bmi = weight / (height^2)
label var bmi "Body Mass Index kg/m^2"

/* replace extreme outliers with missing values: q. should we do this based on physical values or stats? */
replace bmi = . if bmi >= 100 & age >= 18
replace bmi = . if bmi <10 & age >= 18

/* Blood Pressure */
/* take the average of two systolic measurements */
gen bp_systolic = (hv93a + hv93b) / 2
label var bp_systolic "systolic BP taken as average of two measures"

/* take the average of two systolic measurements */
gen bp_diastolic = (hv94a + hv94b) / 2
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
gen diagnosed_illness = hv23
label var diagnosed_illness "self-reported diagnosis in the last 1 year"

gen bp_hypertension = 0
replace bp_hypertension = 1 if diagnosed_illness == 2
replace bp_hypertension = . if mi(diagnosed_illness)
label var bp_hypertension "self-reported diagnosis of hypertension"

/* self-reported hypertension + BP high stage 2 */
gen bp_high = 0
replace bp_high = 1 if (bp_high_stage2 == 1 | bp_hypertension == 1)
replace bp_high = . if mi(bp_high_stage2) & mi(bp_hypertension)
label var bp_high "self-reported hypertension and/or measured BP high stage 2"

/* Respiratory Disease */
gen resp_illness = 0
replace resp_illness = 1 if diagnosed_illness == 6
replace resp_illness = . if mi(diagnosed_illness)
label var resp_illness "self-reported asthma or chronic respiratory failure"

/* Chronic heart disease */
gen chronic_heart_dz = 0
replace chronic_heart_dz = 1 if diagnosed_illness == 3
replace chronic_heart_dz = . if mi(diagnosed_illness)
label var chronic_heart_dz "self-reported chronic heart disease"

/* Diabetes */
gen diabetes = 0
/* standard WHO definition of diabetes is >=126mg/dL if fasting and >=200 if not */
replace diabetes = 1 if (hv91a >= 126 & hv91 == 1) | (hv91a >= 200 & hv91 == 2 & !mi(hv91a))
replace diabetes = . if mi(hv91a) | mi(hv91)
label var diabetes "blood sugar >126mg/dL if fasting, >200mg/dL if not"

/* Cancer - non-haematological */
gen cancer_non_haem = 0
/* respiratory system, gastrointestinal system, genitourinary system, breast, tumor (any type), skin cancer */
replace cancer_non_haem = 1 if (diagnosed_illness == 11 | diagnosed_illness == 12 | diagnosed_illness == 13 | diagnosed_illness == 14 | diagnosed_illness == 27 | diagnosed_illness == 29)
replace cancer_non_haem = . if mi(diagnosed_illness)
label var cancer_non_haem "self-reported non haematological cancer"

/* Liver disease */
gen liver_dz = 0
replace liver_dz = 1 if diagnosed_illness == 18
replace liver_dz = . if mi(diagnosed_illness)
label var liver_dz "self-reported chronic liver disease"

/* Stroke */
gen stroke = 0
replace stroke = 1 if diagnosed_illness == 5
replace stroke = . if mi(diagnosed_illness)
label var stroke "self-reported stroke cerebro vascular accident"

/* Kidney disease */
gen kidney_dz = 0
replace kidney_dz = 1 if (diagnosed_illness == 15 | diagnosed_illness == 16)
replace kidney_dz = . if mi(diagnosed_illness)
label var kidney_dz "self-reported renal stones or chronic renal disease"

/* Autoimmune disease */
gen autoimmune_dz = 0
replace autoimmune_dz = 1 if (diagnosed_illness == 19 | diagnosed_illness == 20)
replace autoimmune_dz = . if mi(diagnosed_illness)
label var autoimmune_dz "self-reported psoriasis or rheumatoid arthritis"

/* drop most raw question variables */
drop hv* qe* qs* q77_intropersonalhabit flq85 

/* save limited dataset with only comorbidity data */
save $health/dlhs/data/dlhs_covid_comorbidities, replace
