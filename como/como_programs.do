/****************************************/
/* set globals used throughout analysis */
/****************************************/
global comorbid_vars age18_40 age40_50 age50_60 age60_70 age70_80 age80_ female male bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global comorbid_vars_no_age_sex bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global comorbid_conditions_no_diab bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz 

global comorbid_conditions_only bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

/* define the biomarker variables from DLHS/AHS */
global comorbid_biomarker_vars bmi_obeseI bmi_obeseII bmi_obeseIII bp_high diabetes_uncontr 

/* define the non-biomarker variables from GBD */
global comorbid_gbd_vars asthma_ocs autoimmune_dz haem_malig_1 cancer_non_haem_1 chronic_heart_dz chronic_resp_dz immuno_other_dz kidney_dz liver_dz neuro_other stroke_dementia

/*******************************/
/* define some helper programs */
/*******************************/
