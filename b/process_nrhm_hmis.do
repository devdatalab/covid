/* processes excel files from NRHM HMIS and saves as stata files and csv's */
/* data source: https://nrhm-mis.nic.in/hmisreports/frmstandard_reports.aspx */

/* make directories */
cap mkdir $health/nrhm_hmis
cap mkdir $health/nrhm_hmis/raw/
cap mkdir $health/nrhm_hmis/raw/itemwise_comparison/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/district
cap mkdir $health/nrhm_hmis/raw/itemwise_monthly/subdistrict
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

/* Convert XML Data into csv for 2019-2020*/
shell python -c "from b.retrieve_case_data import read_hmis_csv; read_hmis_csv('2019-2020','$tmp')"

/* Append all csv data for 2019-2020*/
local filelist_2020 : dir "$tmp/nrhm_hmis/itemwise_monthly/district/2019-2020" files "*.csv"
local temp

foreach i in `filelist_2020'{
  preserve
  import delimited "$tmp/nrhm_hmis/itemwise_monthly/district/2019-2020/`i'", clear
  save temp,replace
  restore
  append using temp, force
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

/* Can't seem to make a built directory */
// mkdir $health/nrhm_hmis/built
// save $health/nrhm_hmis/built/district_wise_health_data

/* This doesn't seem to work either */
save $health/nrhm_hmis/district_wise_health_data, replace
