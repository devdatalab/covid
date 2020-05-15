/* processes excel files from NRHM HMIS and saves as stata files and csv's */
/* data source: https://nrhm-mis.nic.in/hmisreports/frmstandard_reports.aspx */

/* make directories for hmis data*/
cap mkdir $health/hmis
cap mkdir $health/hmis/raw/
cap mkdir $health/hmis/raw/itemwise_comparison/
cap mkdir $health/hmis/raw/itemwise_monthly/
cap mkdir $health/hmis/raw/itemwise_monthly/district
cap mkdir $health/hmis/raw/itemwise_monthly/subdistrict
cap mkdir $health/hmis/data_dictionary/
cap mkdir $tmp/hmis
cap mkdir $tmp/hmis/itemwise_monthly/
cap mkdir $tmp/hmis/itemwise_monthly/district
cap mkdir $tmp/hmis/itemwise_monthly/subdistrict
cap mkdir $tmp/hmis/data_reporting_status/

/*********/
/* Unzip */
/*********/

/* itemwise monthly */
foreach level in district subdistrict {
  local filelist : dir "$health/hmis/raw/itemwise_monthly/`level'/" files "*.zip"
  foreach file in `filelist' {
    !unzip -u $health/hmis/raw/itemwise_monthly/`level'/`file' -d $tmp/hmis/itemwise_monthly/`level'/
  }
}

/*************************************************************/
/* Ingest and Process District  Health/Itemwise Monthly Data */
/*************************************************************/

/* Change directory to run python code */
cd $ddl/covid

/* Save all years in a local by Looping over all years in district directory*/
local years: dir "$tmp/hmis/itemwise_monthly/district/" dirs "*"

/* For every year of data: Convert every State's XML Data into csv using the .py script */
foreach year in `years'{
  shell python -c "from b.retrieve_case_data import read_hmis_csv; read_hmis_csv('`year'','$tmp')"
}

/* Save all years in a macro by Looping over all years in district directory*/
local years: dir "$tmp/hmis/itemwise_monthly/district/" dirs "*"

/* For every year of data: Append All States' Data, add variable definitions and save */
foreach year in `years'{

  /* Append all States' Data for the year */

  /* Make a local to hold all state csv files' names  */
  local filelist : dir "$tmp/hmis/itemwise_monthly/district/`year'" files "*.csv"
  
  /* save an empty tempfile to hold all appended states' data */
  clear
  save $tmp/hmis_allstates, replace emptyok
  
  /* cycle through each state file */
  foreach i in `filelist'{
  
    /* skip the variable definitions */
    if "`i'" == "hmis_variable_definitions.csv" continue
  
    /* import  the csv*/
    import delimited "$tmp/hmis/itemwise_monthly/district/`year'/`i'", varn(1) clear
  
    /* double check to make sure this has real data, and is not the variable defintion csv  */
    cap assert `c(k)' > 4
    if _rc != 0 {
      di "`i' is not a state dataset, skipping"
      continue
    }
    
    /* generate a state and year variable */
    gen state = "`i'"
    gen year = "`year'"
  
    /* append the new state to the full data */
    append using $tmp/hmis_allstates, force
    save $tmp/hmis_allstates, replace
  }
  
  /* remove the .csv from the state name */
  replace state = subinstr(state, ".csv", "", .)
  
  /* replace month as a numeric integer from 1-12 */
  gen month_num = month(date(month,"M"))

  /*  put month name as value labels
  (labutil has a useful function for this, hence the ssc install) */
  ssc install labutil
  labmask month_num, values(month) 
  
  /* Keep just one month variable */
  drop month
  rename month_num month
  
  /* Drop missing months, generated when month was named "Total" */
  drop if mi(month)

  /* Save the financial year as a separate variable, remove it if necessary */
  gen year_financial = year

  /* Replace year as integer; earlier part of string if Apr-Dec; latter part if  Jan-Mar */
  replace year = regexs(1) if (regexm(year, "^(.+)-(.+)$") & month <=12 & month >= 4) 
  replace year = regexs(2) if (regexm(year, "^(.+)-(.+)$") & month <4) 
  destring year, replace
  
  /* bring identifying variables to the front */  
  /* For  years 2017-2021, where the variable "category" exists*/
  capture confirm variable category
  if (_rc == 0){ 

    order state district year month category year_financial
  }

  /* For years 2008-2017, where the variable "category" doesn't exist*/
  capture confirm variable category
  if (_rc != 0){
    /* We assume data reported is total since no  private/public or urban/rural here */
    gen category = "Total [(A+B) or (C+D)]"
    order state district year month category year_financial
  }
  
  /* Replace variable names with their labels, formatting them to be stata friendly */
  foreach v of varlist v* {
      local varlabel : variable label `v'
      local varlabel = subinstr("`varlabel'", "." , "_" , .)
      local varlabel = subinstr("`varlabel'", "'", "", .) 
      local varlabel = subinstr("`varlabel'", " ", "_", .)
      local varlabel = subinstr("`varlabel'", "(","_",.)
      local varlabel = subinstr("`varlabel'", ")","",.)    
      rename `v'  v_`varlabel'
  }

  /* Save data */
  save $health/hmis/hmis_dist_clean_`year', replace
  
  /* Label the variables according to their data dictionary */
  /* read in variable definitions and save as a stata file */
  import delimited using $tmp/hmis/itemwise_monthly/district/`year'/hmis_variable_definitions.csv, clear charset("utf-8")

  /* rename variable headers */
  ren v1 variable
  ren v2 description
  drop in 1

  /* Copy variable description as labels to variables encoded by in hmis_dist_clean_`year' */
  merge using $health/hmis/hmis_dist_clean_`year'
  drop _merge
  local i = 1
  foreach v of varlist v_* {
    local label = description[`i']
    label var `v' "`label'"
    local i = `i' + 1
  }
  
  /* Remove the variable and description fields in the main dataset from the data_dictionary */
  drop variable description
  
  /* save variable descriptions */
  save $health/hmis/data_dictionary/hmis_variable_definitions_`year', replace

  /* Save labelled and cleaned data */
  save $health/hmis/hmis_dist_clean_`year', replace

}

/**********************************************************/
/* Process Number of Hospitals/data_reporting_status data */
/**********************************************************/

/* Unzip District Reporting Status Data from zip files and save .xls files in $tmp*/
local filelist : dir "$health/hmis/raw/data_reporting_status" files "*.zip"
foreach file in `filelist' {
  !unzip -u $health/hmis/raw/data_reporting_status/`file' -d $tmp/hmis/data_reporting_status
}

/* Change directory so you can reference the python script correctly */
cd $ddl/covid

/* Loop over all years to extract .xls(xml) files to csv */
local years: dir "$tmp/hmis/data_reporting_status" dirs "*-*"
foreach year in `years'{
  shell python -c "from b.retrieve_case_data import read_hmis_csv_hospitals; read_hmis_csv_hospitals('`year'','$tmp')"
}

/* Loop over all csv files and append them into a .dta file */
local years: dir "$tmp/hmis/data_reporting_status" dirs "*-*"
foreach year in `years'{
  
  /* Append all csv data for the year */
  local filelist : dir "$tmp/hmis/data_reporting_status/`year'" files "*.csv"
  
  /* save an empty tempfile to hold all appended states */
  clear
  save $tmp/hmis_allstates_hospitals, replace emptyok
  
  /* cycle through each state file */
  foreach i in `filelist'{

    /* import  the csv*/
    import delimited "$tmp/hmis/data_reporting_status/`year'/`i'", varn(1) clear
    
    /* generate a state and year variable */
    gen state = "`i'"
    gen year = "`year'"

    /* append the new state to the full data */
    append using $tmp/hmis_allstates_hospitals, force
    save $tmp/hmis_allstates_hospitals, replace
  }

  
  /* remove the .csv from the state name */
  replace state = subinstr(state, ".csv", "", .)
  
  /* replace month as a numeric integer from 1-12 */
  gen month_num = month(date(month,"M"))
  
  /*  put month name as value labels
  (labutil has a useful function for this, hence the ssc install) */
  ssc install labutil
  labmask month_num, values(month) 
  
  /* Keep just one month variable */
  drop month
  rename month_num month
  
  /* Save the financial year as a separate variable, remove it if necessary */
  gen year_financial = year
  
  /* Replace year as integer; earlier part of string if Apr-Dec; latter part if  Jan-Mar */
  replace year = regexs(1) if (regexm(year, "^(.+)-(.+)$") & month <=12 & month >= 4) 
  replace year = regexs(2) if (regexm(year, "^(.+)-(.+)$") & month <4) 
  destring year, replace  
  
  /* bring identifying variables to the front */
  /* For  years 2017-2020, where category exists*/
  capture confirm variable category
  if (_rc == 0){ 
    order state district year month category
  }
  
  
  /* bring identifying variables to the front */
  /* For years 2008-2017, where category doesn't exist*/
  capture confirm variable category
  if (_rc != 0){
    /* We assume data reported is total since no  private/public or urban/rural here */
    gen category = "Total [(A+B) or (C+D)]"
    order state district year month category year_financial
  }
    
  /* save the data */
  save $tmp/hmis/hmis_dist_clean_hospitals_`year', replace

}


/********************************************************************/
/* Merge hospitals reporting data with health/itemwise_monthly data */
/* And append them across years                                     */
/********************************************************************/

/* Append data for early years first */
local early_years "2008-2009 2009-2010 2010-2011 2011-2012 2012-2013 2013-2014 2014-2015 2015-2016 2016-2017"

/* Create temopfile to store all years' data */
clear
save $tmp/hmis_allyears, replace emptyok

/* Loop over early_years and 
1) Merge itemwise_monthly/health data with data reporting status/hospitals reporting data
2) use tempfile to append all years' data into one file */
foreach year in `early_years'{

  /* Use health data, merge with hospitals data and then save */
  use $health/hmis/hmis_dist_clean_`year', clear
  merge 1:1 state district year month year_financial using $tmp/hmis/hmis_dist_clean_hospitals_`year' 

  /* For unmerged districts drop hospitals data.
  Some 20 odd districts in 2015 are unmerged with hospital data
  due to changes in spelling*/
  drop if _merge == 2
  drop _merge
  
  /* Save merged health + hospitals data */
  save $health/hmis/hmis_dist_clean_`year', replace

  /* Child Immunisations  */
  rename v_10_1_01_TOTAL	hm_vac_bcg
  rename v_10_1_09A_TOTAL	hm_vac_hepb
  rename v_10_1_05_TOTAL hm_vac_opv0
  rename v_10_4_2_TOTAL hm_vac_sessions
  
  /* Hospital Attendance Numbers */
  rename v_14_10_1_a_2	hm_inpatient_adult_m 
  rename v_14_10_1_b_2	hm_inpatient_adult_f
  rename v_14_10_1_a_1	hm_inpatient_kids_m
  rename v_14_10_1_b_1	hm_inpatient_kids_f
  rename v_14_13_1_TOTAL	hm_operation_major
  rename v_14_13_2_TOTAL	hm_operation_minor

  /* Testing */
  rename v_15_1_2_a_1 hm_tests_hiv_m
  rename v_15_1_2_b_1	hm_tests_hiv_f
  rename v_15_1_2_c_1 hm_tests_hiv_f_anc
  
  /* Maternal Health */
  rename v_1_1_TOTAL hm_anc_registered
  rename v_2_1_1_a_TOTAL hm_delivery_anm	
  rename v_2_1_1_b_TOTAL hm_delivery_no_anm
  rename v_4_1_1_b_TOTAL hm_birth_f	
  rename v_4_1_1_a_TOTAL hm_birth_m
  
  /*Maternal Health:
  Instituional Deliveries broken into public and private, so add them both*/
  gen hm_delivery_institutional = v_2_2_TOTAL + v_2_3_TOTAL
  label var hm_delivery_institutional "Number of Institutional Deliveries conducted (Including C-Sections)"

  /* PPE */
  rename v_16_3_02_1 hm_gloves_balance
  rename v_16_3_02_2 hm_gloves_received 
  rename v_16_3_02_3 hm_gloves_unusable
  rename v_16_3_02_4 hm_gloves_distributed
  rename v_16_3_02_5 hm_gloves_total
  
  /* drop other variables */
  drop v_* 

  qui append using $tmp/hmis_allyears
  save $tmp/hmis_allyears, replace
  
}

/* Create a local for recent years */
local later_years "2017-2018 2018-2019 2019-2020 2020-2021"

/* Loop over later_ years and 
1) Merge itemwise_monthly/health data with data reporting status/hospitals reporting data
2) use tempfile to append all years' data into one file */
foreach year in `later_years'{

  /* Use health data, merge with hospitals data and then save  */
  use $health/hmis/hmis_dist_clean_`year', clear
  merge 1:1 state district year month category year_financial using $tmp/hmis/hmis_dist_clean_hospitals_`year' 

  /* Drop unmerged hospitals data for 2020-2021  */
  drop if _merge == 2
  drop _merge
  
  /* Save Merged health + hospitals data */
  save $health/hmis/hmis_dist_clean_`year', replace

  /* Child Immunisations  */
  rename v_9_1_2_TOTAL	hm_vac_bcg
  rename v_9_1_13_TOTAL	hm_vac_hepb
  rename v_9_1_9_TOTAL hm_vac_opv0
  rename v_9_7_2_TOTAL hm_vac_sessions
  
  /* Hospital Attendance Numbers */
  rename v_14_3_1_b_TOTAL	hm_inpatient_adult_m 
  rename v_14_3_2_b_TOTAL	hm_inpatient_adult_f
  rename v_14_3_1_a_TOTAL	hm_inpatient_kids_m
  rename v_14_3_2_a_TOTAL	hm_inpatient_kids_f
  rename v_14_4_4_TOTAL	hm_inpatient_respiratory
  rename v_14_1_1_TOTAL	hm_outpatient_diabetes
  rename v_14_1_2_TOTAL	hm_outpatient_hypertension
  rename v_14_1_9_TOTAL	hm_outpatient_cancer
  rename v_14_5_TOTAL	hm_emergency_total
  rename v_14_6_1_TOTAL	hm_emergency_trauma
  rename v_14_6_5_TOTAL	hm_emergency_heart_attack
  rename v_14_8_1_TOTAL	hm_operation_major
  rename v_14_8_4_TOTAL	hm_operation_minor

  /* Testing */
  rename v_15_1_TOTAL	hm_tests_total 
  rename v_15_3_1_a_TOTAL	 hm_tests_hiv_m
  rename v_15_3_2_a_TOTAL	hm_tests_hiv_f
  rename v_15_3_3_a_TOTAL hm_tests_hiv_f_anc  

  /* Maternal Health */
  rename v_1_1_TOTAL hm_anc_registered
  rename v_2_2_TOTAL hm_delivery_institutional
  rename v_2_1_1_a_TOTAL hm_delivery_anm	
  rename v_2_1_1_b_TOTAL  hm_delivery_no_anm
  rename v_4_1_1_b_TOTAL hm_birth_f	
  rename v_4_1_1_a_TOTAL hm_birth_m
  rename v_2_1_3_TOTAL hm_care_home
  rename v_2_2_2_TOTAL hm_care_institution	

  /* PPE */
  rename v_19_1_1 hm_gloves_balance
  rename v_19_1_2	hm_gloves_received 
  rename v_19_1_3	hm_gloves_unusable
  rename v_19_1_4	hm_gloves_distributed
  rename v_19_1_5	hm_gloves_total
    
  /* Drop all other variables */
  drop v_*
  
  /* Append All years' data sequentially*/
  qui append using $tmp/hmis_allyears
  save $tmp/hmis_allyears, replace

}

/* Get identifiers to the front */
order state district year month category year_financial 

/* rename and label hospitals with their full names */
label var sc "Number of Sub Center Reporting Reporting"
label var phc "Number of Primary Health Center Reporting"
label var chc "Number of Community Health Center Reporting"
label var sdh "Number of Sub District Hospital Reporting"
label var dh  "Number of District Hospital Reporting"
label var total "Total Number of Hospitals Reporting"

rename sc hm_hosp_sc
rename phc hm_hosp_phc
rename chc hm_hosp_chc
rename sdh hm_hosp_sdh
rename dh hm_hosp_dh
rename total hm_hosp_total

/* Label identifiers */
label var state "Name of the State"
label var district "Name of the district"
label var year "Calendar Year"
label var month "Month"
label var category "Total/Rural/Urban/Private/Public"
label var year_financial "Financial Year for whcih the data is reported"

/* Drop 2020-2021 data */
drop if year_financial == "2020-2021"

/* Save data */
save $health/hmis/hmis_clean_small, replace

/*********************************************************/
/* Create year state district matching key for hmis data */
/*********************************************************/

/* Use hmis small dataset to create key on identifiers*/
use $health/hmis/hmis_clean_small, clear
contract year_financial state district

/* Rename Variables for merge clarity*/
rename state hmis_state
rename district hmis_district
rename year_financial hmis_year

/* Save hmis key  */
save $health/hmis/hmis_clean_small_key, replace

/******************************************************/
/* Merge HMIS district key with lgd pc11 district key */
/******************************************************/

/* import data */
use $health/hmis/hmis_clean_small_key, clear

/* collapse dataset */
bys hmis_state hmis_district: keep if _n == 1

/* gen hmis state and district name vars */
gen hmis_state_name = hmis_state
gen hmis_district_name = hmis_district

/* define programs to merge variables */
qui do $ddl/covid/covid_progs.do

/* format variables */
lgd_state_clean hmis_state
lgd_dist_clean hmis_district

/* merge */
lgd_state_match hmis_state
lgd_dist_match hmis_district

/* ren hmis vars */
ren (hmis_state_name hmis_district_name) (hmis_state hmis_district)

/* save matched dataset */
save $health/hmis/hmis_district_key, replace


