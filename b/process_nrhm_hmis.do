/* processes excel files from NRHM HMIS and saves as stata files and csv's */
/* data source: https://nrhm-mis.nic.in/hmisreports/frmstandard_reports.aspx */

/* make directories */
cap mkdir $health/nrhm_hmis
cap mkdir $health/nrhm_hmis/raw/
cap mkdir $health/nrhm_hmis/raw/itemwise_comparison/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/district
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/subdistrict
cap mkdir $health/nrhm_hmis/built
cap mkdir $tmp/nrhm_hmis
cap mkdir $tmp/nrhm_hmis/itemwise_monthly/
cap mkdir $tmp/nrhm_hmis/itemwise_monthly/district
cap mkdir $tmp/nrhm_hmis/itemwise_monthly/subdistrict

/*********/
/* Unzip */
/*********/

/* itemwise monthly */
foreach level in district subdistrict {
  local filelist : dir "$health/nrhm_hmis/raw/itemwise_monthly/`level'/" files "*.zip"
  foreach file in `filelist' {
    !unzip -u $health/nrhm_hmis/raw/itemwise_monthly/`level'/`file' -d $tmp/nrhm_hmis/itemwise_monthly/`level'/
  }
}


/***************************/
/* Ingest and Process Data */
/***************************/
cd $ddl/covid

/* set the year- in the future we can loop over all the years and either save the 
   separately or in one full dataset with all years */
local year "2019-2020"

/* Convert XML Data into csv for 2019-2020*/
shell python -c "from b.retrieve_case_data import read_hmis_csv; read_hmis_csv('`year'','$tmp')"

/* Append all csv data for 2019-2020*/
local filelist : dir "$tmp/nrhm_hmis/itemwise_monthly/district/2019-2020" files "*.csv"

/* save an empty tempfile to hold all appended states */
clear
tempfile allstates
save `allstates', emptyok

/* cycle through each state file */
foreach i in `filelist'{

  /* skip the variable definitions */
  if "`i'" == "hmis_variable_definitions.csv" continue

  /* import  the csv*/
  import delimited "$tmp/nrhm_hmis/itemwise_monthly/district/2019-2020/`i'", varn(1) clear

  /* double check to make sure this has real data, and is not the variable defintion csv  */
  cap assert `c(k)' > 4
  if _rc != 0 {
    di "`i' is not a state dataset, skipping"
    continue
  }
  
  /* generate a state and year variable */
  gen state = "`i'"
  gen year = "`year'"

  /* bring identifying variables to the front */
  order state district year month category

  /* append the new state to the full data */
  append using `allstates', force
  save `allstates', replace
}

/* Rename important varibales */
rename v4 gloves_balance_last_month  
rename v193 inpatient_acute_respiratory
rename v194 inpatient_tuberculosis
rename v198 emergency_total
rename v231 testing_lab_tests_total
rename v108 bcg_vaccination
rename v93 pentav1_vaccination
rename v104 polio_ipv1_vaccination


/* save the data */
cap mkdir $health/nrhm_hmis/built/`year'
save $health/nrhm_hmis/built/`year'/district_wise_health_data
