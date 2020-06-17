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

/* write table header */
cap file close fh
file open fh using $out/app_table_age_bin_prev.tex, write replace

file write fh "\begin{tabular}{lrrrrrr}" _n
file write fh " & \multicolumn{6}{c}{\textbf{Age}} \\ " _n
file write fh " & 18--39 & 40--49 & 50--59 & 60--69 & 70--79 & 80--99 \\ " _n

/* india header */
file write fh " \textbf{India} &  & & & & \\ " _n

/* INDIA PREVALENCE TABLE */
use $tmp/combined, clear
collapse $hr_biomarker_vars [aw=wt], by(age)
merge 1:1 age using $health/gbd/gbd_nhs_conditions_india, keep(match) nogen
drop gbd_diabetes country *upper *lower *granular
ren gbd_* *

/* get india age-specific population to weight GBD year vars */
merge 1:1 age using $tmp/india_pop, keep(match) nogen 

/* loop over condition list */
label_vars
foreach condition in $hr_biomarker_vars $hr_gbd_vars {

  /* get variable label for condition */
  local lab: variable label `condition'
  
  file write fh "\hspace{3mm} "
  file write fh "`lab' & "

  qui sum `condition' [aw=india_pop] if inrange(age, 18, 39)
  file write fh %5.1f (`r(mean)' * 100) " & "
  qui sum `condition' [aw=india_pop] if inrange(age, 40, 49)
  file write fh %5.1f (`r(mean)' * 100) " & "
  qui sum `condition' [aw=india_pop] if inrange(age, 50, 59)
  file write fh %5.1f (`r(mean)' * 100) " & "
  qui sum `condition' [aw=india_pop] if inrange(age, 60, 69)
  file write fh %5.1f (`r(mean)' * 100) " & "
  qui sum `condition' [aw=india_pop] if inrange(age, 70, 79)
  file write fh %5.1f (`r(mean)' * 100) " & "
  qui sum `condition' [aw=india_pop] if inrange(age, 80, 99)
  file write fh %5.1f (`r(mean)' * 100) " \\ " _n
}

/* UK HEADER */
file write fh " & & & & & \\ " _n
file write fh " \textbf{United Kingdom} &  & & & & \\ " _n

/* UNITED KINGDOM PREVALENCE TABLE */

/* combine UK prevalence data */
use $tmp/uk_prevalences, clear
merge 1:1 age using $health/gbd/gbd_nhs_conditions_uk, keep(match) nogen
ren gbd_* *
drop *upper *granular *lower country
ren uk_prev_* *
ren hypertension_both bp_high

/* TEMP: set obesity/overweight which we don't have */
foreach i in I II III {
  gen bmi_obese`i' = 0
}
ren diabetes diabetes_uncontr

/* get india age-specific population to weight GBD year vars */
merge 1:1 age using $tmp/uk_pop, keep(match) nogen 

/* loop over condition list */
label_vars
foreach condition in $hr_biomarker_vars $hr_gbd_vars {

  /* get variable label for condition */
  local lab: variable label `condition'
  
  file write fh "\hspace{3mm} " 
  file write fh "`lab' & "

  qui sum `condition' [aw=uk_pop] if  inrange(age, 18, 39)
  file write fh %5.1f (`r(mean)' * 100) " & " 
  qui sum `condition' [aw=uk_pop] if  inrange(age, 40, 49)
  file write fh %5.1f (`r(mean)' * 100) " & " 
  qui sum `condition' [aw=uk_pop] if  inrange(age, 50, 59)
  file write fh %5.1f (`r(mean)' * 100) " & " 
  qui sum `condition' [aw=uk_pop] if  inrange(age, 60, 69)
  file write fh %5.1f (`r(mean)' * 100) " & " 
  qui sum `condition' [aw=uk_pop] if  inrange(age, 70, 79)
  file write fh %5.1f (`r(mean)' * 100) " & " 
  qui sum `condition' [aw=uk_pop] if  inrange(age, 80, 99)
  file write fh %5.1f (`r(mean)' * 100) " \\ " _n
  
}

file write fh "\end{tabular}" _n

file close fh

