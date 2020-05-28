/* Combine AHS and DLHS data */

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
ren hv02 sl_no

/* match variables to format in AHS */
tostring sl_no, format("%05.0f") replace

/* mark as dlhs */
gen survey = 1

/* append the ahs data */
append using $health/ahs/ahs_cab

/* mark as ahs */
replace survey = 2 if mi(survey)

/************/
/* Cleaning */
/************/

/* AGE */
gen age_new = .

/* use AHS calculated age if it exists */
replace age_new = age_calc if !mi(age_calc)

/* use AHS/DLHS reported age if the calculated age does not exist */
replace age_new = age if mi(age_new) & !mi(age)

/* use age from the hosehold survey for AHS observations with no matched CAB observation */
replace age_new = age_comb if mi(age_new) & !mi(age_comb)

/* replace age with age_new */
drop age age_calc age_comb
ren age_new age

/* AGE  */
drop if age < 18

/* SEX */
/* use the AHS household sex for observations with no matched CAB observation */
replace sex = sex_comb if mi(sex) & !mi(sex_comb)

/* SAMPLE */
/* define a variable to clarify the sample for each variable */
gen sample = ahs_merge
replace sample = 4 if dlhs_merge == 2 & !mi(dlhs_merge)
replace sample = 5 if dlhs_merge == 3 & !mi(dlhs_merge)
cap label define sample 1 "1 AHS cab" 2 "2 AHS comb" 3 "3 AHS cab & comb" 4 "4 DLHS comb" 5 "5 DLHS cab & comb"
label values sample sample
label var sample "DLHS or AHS modules for each observation"

/* USUAL RESIDENCE */
/* about 20% of the AHS COMB dataset is missing information on residence.  
   if we drop non-usual residents, then we have to decide whether we keep or drop the missing values */
replace usual_residance = usual_residance_comb if mi(usual_residance) & !mi(usual_residance_comb)
keep if usual_residance == 1 | mi(usual_residance)

/* PREGNANT WOMEN 
   we do not have pregnant women for AHS comb data, but for all DLHS. we should keep pregnant women and then just 
   exclude them from the measured comorbidities for both AHS and DLHS */
/* drop if pregnant == 1 & !mi(pregnant) */

save $health/dlhs/data/dlhs_ahs_merged, replace
