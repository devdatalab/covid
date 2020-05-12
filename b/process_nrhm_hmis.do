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

/* Save all years in a macro by Looping over all years in district directory*/
local years: dir "$tmp/nrhm_hmis/itemwise_monthly/district/" dirs "*"

/* After looping over the years macro:
1.Make directory for all the years(This is independent of the python code)
2.Convert XML Data into csv for all years using the .py script */
foreach year in `years'{
  cap mkdir $health/nrhm_hmis/built/`year'
  shell python -c "from b.retrieve_case_data import read_hmis_csv; read_hmis_csv('`year'','$tmp')"

}

/* Save all years in a macro by Looping over all years in district directory*/
local years: dir "$tmp/nrhm_hmis/itemwise_monthly/district/" dirs "*"

foreach year in `years'{
  
  /* Append all csv data for 2019-2020*/
  local filelist : dir "$tmp/nrhm_hmis/itemwise_monthly/district/`year'" files "*.csv"
  
  /* save an empty tempfile to hold all appended states */
  clear
  save $tmp/hmis_allstates, replace emptyok
  
  /* cycle through each state file */
  foreach i in `filelist'{
  
    /* skip the variable definitions */
    if "`i'" == "hmis_variable_definitions.csv" continue
  
    /* import  the csv*/
    import delimited "$tmp/nrhm_hmis/itemwise_monthly/district/`year'/`i'", varn(1) clear
  
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
  labmask month_num, values(month) lblname(name_of_the_month)
  
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
  /* For  years 2017-2020, where category exists*/
  capture confirm variable category
  if (_rc == 0){ 
  order state district year month category
  }
  
  /* bring identifying variables to the front */
  /* For years 2008-2017, where category doesn't exist*/
  capture confirm variable category
  if (_rc != 0){
  order state district year month 
  }
  
  /* Replace variable names with their labels(stata friendly) */
  foreach v of varlist v* {
      local varlabel : variable label `v'
      local varlabel = subinstr("`varlabel'", "." , "_" , .)
      local varlabel = subinstr("`varlabel'", "'", "", .) 
      local varlabel = subinstr("`varlabel'", " ", "_", .)
      local varlabel = subinstr("`varlabel'", "(","_",.)
      local varlabel = subinstr("`varlabel'", ")","",.)    
      di "`varlabel'"
      rename `v'  v_`varlabel'
  }
      
  /* save the data */
  save $health/nrhm_hmis/built/`year'/district_wise_health_data_`year', replace

  /* read in variable definitions and save as a stata file */
  import delimited using $tmp/nrhm_hmis/itemwise_monthly/district/`year'/hmis_variable_definitions.csv, clear charset("utf-8")

  /* rename variable headers */
  ren v1 variable
  ren v2 description
  drop in 1

  /* save variable descriptions */
  save $health/nrhm_hmis/built/`year'/hmis_variable_definitions, replace


}

/**********************************************************/
/* Process Number of Hospitals/data_reporting_status data */
/**********************************************************/
cap mkdir $tmp/nrhm_hmis
cap mkdir $tmp/nrhm_hmis/data_reporting_status/

/* Unzip District Reporting Status Data from zip files and save .xls files in $tmp*/
local filelist : dir "$health/nrhm_hmis/raw/data_reporting_status" files "*.zip"
foreach file in `filelist' {
  !unzip -u $health/nrhm_hmis/raw/data_reporting_status/`file' -d $tmp/nrhm_hmis/data_reporting_status
}

/* Change directory so you can reference the python script correctly */
cd $ddl/covid

/* Loop over all years to extract .xls(xml) files to csv */
/* Since the .xls files are actually xml files we extract them through a python function below */
local years: dir "$tmp/nrhm_hmis/data_reporting_status" dirs "*-*"
foreach year in `years'{
  shell python -c "from b.retrieve_case_data import read_hmis_csv_hospitals; read_hmis_csv_hospitals('`year'','$tmp')"
}

/* Loop over all csv files and append them into a .dta file */
local years: dir "$tmp/nrhm_hmis/data_reporting_status" dirs "*-*"
foreach year in `years'{
  
  /* Append all csv data for the year */
  local filelist : dir "$tmp/nrhm_hmis/data_reporting_status/`year'" files "*.csv"
  
  /* save an empty tempfile to hold all appended states */
  clear
  save $tmp/hmis_allstates_hospitals, replace emptyok
  
  /* cycle through each state file */
  foreach i in `filelist'{

    /* import  the csv*/
    import delimited "$tmp/nrhm_hmis/data_reporting_status/`year'/`i'", varn(1) clear
    
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
  labmask month_num, values(month) lblname(name_of_the_month)
  
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
  order state district year month 
  }
    
  /* save the data */
  save $health/nrhm_hmis/built/`year'/district_wise_health_data_hospitals_`year', replace

}


/*************************************************************/
/* Merge hospitals reporting data with itemwise_monthly data */
/* And append them across years                              */
/*************************************************************/

/* Create a local for recent years */
/* Is redefining a local you've used before in a do file
a good idea?*/
local years "2017-2018 2018-2019 2019-2020 2020-2021"

/* Create temopfile to store all years' data */
clear
save $tmp/hmis_allyears, replace emptyok 

/* Loop over different years' and 
1) Merge itemwise_monthly data with hospitals reporting data
2) use tempfile to append all years' data into one file */
foreach year in `years'{
  use $health/nrhm_hmis/built/`year'/district_wise_health_data_`year',clear
  /* Child Immunisations  */
  rename v_9_1_2_TOTAL	vaccine_birth_BCG
  rename v_9_1_13_TOTAL	vaccine_birth_HepB
  rename v_9_1_9_TOTAL vaccine_birth_OPV0
  rename v_9_7_2_TOTAL vaccine_sessions
  
  /* Hospital Attendance Numbers */
  rename v_14_3_1_b_TOTAL	inpatient_adult_male 
  rename v_14_3_2_b_TOTAL	inpatient_adult_female
  rename v_14_3_1_a_TOTAL	inpatient_kids_male
  rename v_14_3_2_a_TOTAL	inpatient_kids_female
  rename v_14_4_4_TOTAL	inpatient_respiratory
  rename v_14_1_1_TOTAL	outpatient_diabetes
  rename v_14_1_2_TOTAL	outpatient_hypertension
  rename v_14_1_9_TOTAL	outpatient_cancer
  rename v_14_5_TOTAL	emergency_total
  rename v_14_6_1_TOTAL	emergency_trauma
  rename v_14_6_5_TOTAL	emergency_heart_attack
  rename v_14_8_1_TOTAL	operation_major
  rename v_14_8_4_TOTAL	operation_minor

  /* Testing */
  rename v_15_1_TOTAL	tests_total 
  rename v_15_3_1_a_TOTAL	 tests_hiv_male
  rename v_15_3_2_a_TOTAL	tests_hiv_female
  rename v_15_3_3_a_TOTAL test_hiv_female_anc  
  /* Maternal Health */
  rename v_1_1_TOTAL maternal_anc_registered
  rename v_2_2_TOTAL maternal_delivery_institutional
  rename v_2_1_1_a_TOTAL maternal_delivery_anm	
  rename v_2_1_1_b_TOTAL  maternal_delivery_no_anm
  rename v_4_1_1_b_TOTAL maternal_birth_female	
  rename v_4_1_1_a_TOTAL maternal_birth_male
  rename v_2_1_3_TOTAL maternal_care_home
  rename v_2_2_2_TOTAL maternal_care_institution	

  /* PPE */
  rename v_19_1_1 gloves_balance
  rename v_19_1_2	gloves_received 
  rename v_19_1_3	gloves_unusable
  rename v_19_1_4	gloves_distributed
  rename v_19_1_5	gloves_total
  
  merge 1:1 state district year month category year_financial using $health/nrhm_hmis/built/`year'/district_wise_health_data_hospitals_`year'
  
  qui append using $tmp/hmis_allyears
  save $tmp/hmis_allyears, replace

  /* Drop all other variables */
  drop v_* _merge

}

local years "2008-2009 2010-2011 2011-2012 2012-2013 2013-2014 2014-2015 2015-2016 2016-2017"
foreach year in `years'{
  
  use $health/nrhm_hmis/built/`year'/district_wise_health_data_`year',clear

   /* Child Immunisations  */
  rename v_10_1_01_TOTAL	vaccine_birth_BCG
  rename v_10_1_09A_TOTAL	vaccine_birth_HepB
  rename v_10_1_05_TOTAL vaccine_birth_OPV0
  rename v_10_4_2_TOTAL vaccine_sessions
  
  /* Hospital Attendance Numbers */
  rename v_14_10_1_a_2	inpatient_adult_male 
  rename v_14_10_1_b_2	inpatient_adult_female
  rename v_14_10_1_a_1	inpatient_kids_male
  rename v_14_10_1_b_1	inpatient_kids_female
  rename v_14_13_1_TOTAL	operation_major
  rename v_14_13_2_TOTAL	operation_minor

  /* Testing */
  rename v_15_1_2_a_1 tests_hiv_male
  rename v_15_1_2_b_1	tests_hiv_female
  rename v_15_1_2_c_1 tests_hiv_female_anc
  
  /* Maternal Health */
  rename v_1_1_TOTAL maternal_anc_registered
  /* Insttituional Deliveries broken into public and private, so add them both*/
  gen maternal_delivery_institutional = v_2_2_TOTAL + v_2_3_TOTAL
  rename v_2_1_1_a_TOTAL maternal_delivery_anm	
  rename v_2_1_1_b_TOTAL maternal_delivery_no_anm
  rename v_4_1_1_b_TOTAL maternal_birth_female	
  rename v_4_1_1_a_TOTAL maternal_birth_male 

  /* PPE */
  rename v_16_3_02_1 gloves_balance
  rename v_16_3_02_2 gloves_received 
  rename v_16_3_02_3 gloves_unusable
  rename v_16_3_02_4 gloves_distributed
  rename v_16_3_02_5 gloves_total

  /* drop other variables */
  drop v_*

  /* Merge with hospitals data */
  merge 1:1 state district year month  year_financial using $health/nrhm_hmis/built/`year'/district_wise_health_data_hospitals_`year'
  
  qui append using $tmp/hmis_allyears
  save $tmp/hmis_allyears, replace
  
}

/* Get identifiers to the front */
order state district year month category year_financial 

/* rename hospitals with their full names */
rename sc sub_center
rename phc primary_health_center
rename chc community_health_center
rename sdh sub_district_hospital
rename dh district_hospital
rename total total_hospitals

/* Label identifiers */
label var state "Name of the State"
label var district "Name of the district"
label var year "Calendar Year"
label var category "Total/Rural/Urban/Private/Public"
label var year_financial "Financial Year for whcih the data is reported"

/* For unmerged district, keep itemwise_monthly data*/
keep if _merge == 1 | _merge == 3

/* Drop unnecessary variables */
drop v_* _merge

/* Save Recent Years' data */
save $health/nrhm_hmis/built/district_wise_health_data_all, replace

/**************************************/
/* Create state district matching key */
/**************************************/
use $health/nrhm_hmis/built/district_wise_health_data_all, clear
contract year_financial state district

rename state hmis_state
rename district hmis_district
rename year hmis_year

/* Currently for 2017/18- 2019-2020 data, all years have same # of districts */
save $health/nrhm_hmis/built/district_wise_health_data_all_key, replace


/******************************************************/
/* Merge HMIS district key with lgd pc11 district key */
/******************************************************/

/* import data */
use $health/nrhm_hmis/built/district_wise_health_data_all_key, clear

/* define programs to merge variables */
qui do $ddl/tools/do/lgd_state_match.do
qui do $ddl/tools/do/lgd_district_match.do

/* format variables */
lgd_state_format hmis_state
lgd_dist_format hmis_district

/* merge */
lgd_state_match hmis_state
lgd_dist_match hmis_district

/* check dataset before saving */

/* save matched dataset */
/* in temp folder for now, check before saving in data tree */
save $tmp/lgd_pc11_hmis_district_key, replace
