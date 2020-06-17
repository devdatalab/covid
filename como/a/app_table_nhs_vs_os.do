/*************************************************************************/
/* create a table comparing opensafely prevalences to UK NHS prevalences */
/*************************************************************************/

/* set variable labels */
cap prog drop label_vars
prog def label_vars
  label var bmi_obeseI        "Obese (class I)"
  label var bmi_obeseII       "Obese (class II)"
  label var bmi_obeseIII      "Obese (class III)"
  label var bp_high           "Hypertension"
  label var diabetes_uncontr  "Diabetes"
  label var asthma_ocs        "Asthma"
  label var autoimmune_dz     "Psoriasis, Rheumatoid"
  label var haem_malig_1      "Haematological Cancer"
  label var cancer_non_haem_1 "Non-haematological Cancer"
  label var chronic_heart_dz  "Chronic Heart Disease"
  label var chronic_resp_dz   "Chronic Respiratory Disease"
  label var immuno_other_dz   "Other Immunosuppressive Conditions"
  label var kidney_dz         "Kidney Disease"
  label var liver_dz          "Chronic Liver Disease"
  label var neuro_other       "Other Neurological Condition"
  label var stroke_dementia   "Stroke / Dementia"
end

/* UNITED KINGDOM PREVALENCE TABLE */

/* combine UK prevalence data */
use $tmp/prev_uk_nhs_matched, clear

/* get age-specific population for weighted collapse */
merge 1:1 age using $tmp/uk_pop

/* collapse to population prevalence */
drop male
ren prev_* *

/* merge in OpenSafely prevalences */
merge 1:1 age using $tmp/prev_uk_os, nogen
foreach v in $hr_biomarker_vars $hr_gbd_vars {
  bys age: egen t = mean(prev_`v')
  replace prev_`v' = t if mi(prev_`v')
  drop t
}

/* limit to ages 18-99 */
keep if inrange(age, 18, 99)

/* BEGIN TABLE OUTPUT */
cap file close fh
file open fh using $out/app_table_os_vs_nhs.tex, write replace

file write fh "\begin{tabular}{lcc}" _n
file write fh " & Population & OpenSAFELY \\ " _n
file write fh " & Prevalence & Prevalence \\ " _n

/* loop over conditions sourced in NHS */
label_vars
file write fh "\textbf{Source: NHS Health Survey for England} & & \\ " _n
foreach condition in $hr_biomarker_vars {

  /* get variable label for condition */
  local lab: variable label `condition'

  /* put in variable */
  file write fh "\hspace{3mm} " 
  file write fh "`lab' & "

  /* put in our prevalence */
  qui sum `condition' [aw=uk_pop]
  file write fh %5.1f (`r(mean)' * 100) " & "

  /* put in OpenSAFELY prevalence */
  qui sum prev_`condition' 
  file write fh %5.1f (`r(mean)' * 100) " \\ " _n
}

/* put in COPD */

file write fh "\vspace{5mm} & & \\ " _n
file write fh "\textbf{Source: Clinical Practice Research Datalink} & & \\ " _n
file write fh "\hspace{3mm} " 
file write fh %5.1f "Chronic Respiratory Illness & "
qui sum chronic_resp_dz [aw=uk_pop]
file write fh %5.1f (`r(mean)' * 100) " & "

/* put in OpenSAFELY prevalence */
qui sum prev_chronic_resp_dz
file write fh %5.1f (`r(mean)' * 100) " \\ " _n

/* GBD conditions */
file write fh "\vspace{5mm} & & \\ " _n
file write fh "\textbf{Source: Global Burden of Disease} & & \\ " _n
foreach condition in $hr_gbd_vars  {

  /* get variable label for condition */
  local lab: variable label `condition'

  /* put in variable */
  file write fh "\hspace{3mm} " 
  file write fh "`lab' & "

  /* put in our prevalence */
  qui sum `condition' [aw=uk_pop]
  file write fh %5.1f (`r(mean)' * 100) " & "

  /* put in OpenSAFELY prevalence */
  qui sum prev_`condition' 
  file write fh %5.1f (`r(mean)' * 100) " \\ " _n
}
  
file write fh "\end{tabular}" _n

file close fh

