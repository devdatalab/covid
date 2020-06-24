/* set variable labels */
cap prog drop label_vars
prog def label_vars
  cap label var bmi_obeseI        "Obese (class I)"
  cap label var bmi_obeseII       "Obese (class II)"
  cap label var bmi_obeseIII      "Obese (class III)"
  label var obese_1_2           "Obese (class 1 & 2)"
  label var obese_3  "Obese (class 3)"
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
use $tmp/prev_india, clear
ren prev_* *

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
file write fh " \textbf{England} &  & & & & \\ " _n

/* ENGLAND PREVALENCE TABLE */

/* combine UK prevalence data */
use $tmp/prev_uk_nhs_matched, clear
ren prev_* *

/* get UK age-specific population to weight GBD year vars */
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

