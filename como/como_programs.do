/****************************************/
/* set globals used throughout analysis */
/****************************************/

/* MAIN COMORBID CONDITION SETS USED IN THE PAPER */

/* define age bin indicator variables */
global age_vars age18_40 age40_50 age50_60 age60_70 age70_80 age80_

/* define biomarker variables from DLHS/AHS that match NHS hazard ratio vars */
global hr_biomarker_vars bmi_obeseI bmi_obeseII bmi_obeseIII bp_high diabetes_uncontr diabetes_contr

/* define non-biomarker GBD variables that match NHS hazard ratio vars */
global hr_gbd_vars asthma_ocs autoimmune_dz haem_malig_1 cancer_non_haem_1    ///
    chronic_heart_dz chronic_resp_dz immuno_other_dz kidney_dz liver_dz neuro_other ///
    stroke_dementia

/* define varlist found only in opensafely */
global hr_os_only_vars asthma_no_ocs cancer_non_haem_1_5 cancer_non_haem_5 diabetes_no_measure haem_malig_1_5 haem_malig_5 organ_transplant spleen_dz


/* SOME ADDITIONAL VARIABLE GROUPS USED IN EXPLORATION AND DEBUGGING */

/* define self-report vars found in DLHS/AHS (but not used in risk analysis)  */
global hr_selfreport_vars chronic_heart_dz stroke_dementia liver_dz kidney_dz autoimmune_dz ///
                      cancer_non_haem_1 haem_malig_1 chronic_resp_dz 


/*******************************/
/* define some helper programs */
/*******************************/
/*********************************************************/
/* sc: a function to scatter multiple variables over age */
/*********************************************************/
cap prog drop sc
prog def sc

  syntax varlist, [name(string) yscale(passthru) ylabel(passthru) legend(passthru)]
  tokenize `varlist'

  /* set a default yscale */
  if mi("`yscale'") local yscale yscale(log) 
  if mi("`ylabel'") local ylabel ylabel(.125 .25 1 4 16 64)
  
  /* set a default name */
  if mi("`name'") local name euripides
  
  /* loop over the outcome vars */
  while (!mi("`1'")) {

    /* store the variable label */
    local label : variable label `1'

    /* add the line plot for this variable to the twoway command string */
    local command `command' (line `1' age, `yscale' `ylabel' xtitle("`label'") ytitle("Mortality Hazard Ratio") lwidth(medthick) )

    /* get the next variable in the list */
    mac shift
  }

  /* draw the graph */
  twoway `command', `legend'
  graphout `name'
end
/****************** end sc *********************** */

/************************************************************/
/* scp: a function to compare multiple prevalences over age */
/************************************************************/
cap prog drop scp
prog def scp

  syntax varlist, [name(string) yscale(passthru) yline(passthru) ytitle(passthru) legend(passthru)]
  tokenize `varlist'

  /* set defaults */
  if mi("`yscale'") local yscale
  if mi("`name'") local name euripides
  if mi("`ytitle'") local ytitle ytitle("Prevalence")
  
  /* loop over the outcome vars */
  while (!mi("`1'")) {

    /* store the variable label */
    local label : variable label `1'

    /* add the line plot for this variable to the twoway command string */
    local command `command' (line `1' age, `yscale' xtitle("`label'") `ytitle' lwidth(medthick) )

    /* get the next variable in the list */
    mac shift
  }

  /* draw the graph */
  twoway `command', `yline' name(`name', replace) `legend'
  graphout `name'
end
/****************** end scp *********************** */



// CONDITION LIST

// AGE/SEX
// age18_40
// age40_50
// age50_60
// age60_70
// age70_80
// age80_
// male

// BIOMARKERS (plus diabetes_contr from DLHS/AHS)
// bmi_obeseI
// bmi_obeseII
// bmi_obeseIII
// bp_high
// diabetes_uncontr
// diabetes_contr

// GLOBAL BURDEN OF DISEASE
// asthma_ocs
// autoimmune_dz
// haem_malig_1
// cancer_non_haem_1
// chronic_heart_dz
// chronic_resp_dz
// immuno_other_dz
// kidney_dz
// liver_dz
// neuro_other
// stroke_dementia

// NOT USED
// asthma_no_ocs
// cancer_non_haem_1_5
// cancer_non_haem_5
// diabetes_no_measure
// haem_malig_1_5
// haem_malig_5
// organ_transplant
// spleen_dz
