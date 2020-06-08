/****************************************/
/* set globals used throughout analysis */
/****************************************/

/* MAIN COMORBID CONDITION SETS USED IN THE PAPER */

/* define age bin indicator variables */
global age_vars age18_40 age40_50 age50_60 age60_70 age70_80 age80_

/* define biomarker variables from DLHS/AHS that match NHS hazard ratio vars */
global hr_biomarker_vars bmi_obeseI bmi_obeseII bmi_obeseIII bp_high diabetes_uncontr

/* define non-biomarker GBD variables that match NHS hazard ratio vars */
global hr_gbd_vars asthma_ocs autoimmune_dz haem_malig_1 cancer_non_haem_1    ///
    chronic_heart_dz chronic_resp_dz immuno_other_dz kidney_dz liver_dz neuro_other ///
    stroke_dementia

/* define self-report vars found in DLHS/AHS (but not used in risk analysis)  */
global hr_selfreport_vars chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz 

/* SOME ALTERNATE CONDITION SETS USED BY THE ANALYSIS */
// global comorbid_vars age18_40 age40_50 age50_60 age60_70 age70_80 age80_ female male bmi_not_obese bmi_obeseI ///
//                       bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
//                       cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 
// 
// global comorbid_vars_no_age_sex bmi_not_obese bmi_obeseI ///
//                       bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
//                       cancer_non_haem_1 haem_malig_1 chronic_resp_dz diabetes_uncontr 

global hr_biomarkers_no_diab bmi_not_obese bmi_obeseI ///
                      bmi_obeseII bmi_obeseIII bp_not_high bp_high chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz 


/*******************************/
/* define some helper programs */
/*******************************/
/*********************************************************/
/* sc: a function to scatter multiple variables over age */
/*********************************************************/
cap prog drop sc
prog def sc

  syntax varlist, [name(string) yscale(passthru)]
  tokenize `varlist'

  /* set a default yscale */
  if mi("`yscale'") local yscale yscale(log) ylabel(.125 .25 1 4 16 64)

  /* set a default name */
  if mi("`name'") local name euripides
  
  /* loop over the outcome vars */
  while (!mi("`1'")) {

    /* store the variable label */
    local label : variable label `1'

    /* add the line plot for this variable to the twoway command string */
    local command `command' (line `1' age, `yscale' xtitle("`label'") ytitle("Mortality Hazard Ratio") lwidth(medthick) )

    /* get the next variable in the list */
    mac shift
  }

  /* draw the graph */
  twoway `command'
  graphout `name'
end
/****************** end sc *********************** */

/************************************************************/
/* scp: a function to compare multiple prevalences over age */
/************************************************************/
cap prog drop scp
prog def scp

  syntax varlist, [name(string) yscale(passthru) yline(passthru)]
  tokenize `varlist'

  /* set a default yscale (or not) */
  if mi("`yscale'") local yscale

  /* set a default name */
  if mi("`name'") local name euripides
  
  /* loop over the outcome vars */
  while (!mi("`1'")) {

    /* store the variable label */
    local label : variable label `1'

    /* add the line plot for this variable to the twoway command string */
    local command `command' (line `1' age, `yscale' xtitle("`label'") ytitle("Prevalence") lwidth(medthick) )

    /* get the next variable in the list */
    mac shift
  }

  /* draw the graph */
  twoway `command', `yline' name(`name', replace)
  graphout `name'
end
/****************** end scp *********************** */
