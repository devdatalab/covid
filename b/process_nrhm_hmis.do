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
  
  /* Rename important varibales */
  rename v405 gloves_balance_last_month  
  rename v193 inpatient_acute_respiratory
  rename v194 inpatient_tuberculosis
  rename v198 emergency_total
  rename v231 testing_lab_tests_total
  rename v108 bcg_vaccination
  rename v93 pentav1_vaccination
  rename v104 polio_ipv1_vaccination
  
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

  /* get identifying variables to the front */
  order state district year month category

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
local years "2017-2018 2018-2019 2019-2020"

/* Create temopfile to store all years' data */
clear
save $tmp/hmis_allyears, replace emptyok 

/* Loop over different years, and use tempfile to append all years' data into one file */
foreach year in `years'{
  use $health/nrhm_hmis/built/`year'/district_wise_health_data_`year',clear
  merge 1:1 state district year month category year_financial using $health/nrhm_hmis/built/`year'/district_wise_health_data_hospitals_`year'
  append using $tmp/hmis_allyears
  save $tmp/hmis_allyears, replace
}

/* Get identifiers to the front */
order state district year month category year_financial 

/* Label identifiers */
label var state "Name of the State"
label var district "Name of the district"
label var year "Calendar Year"
label var category "Total/Rural/Urban/Private/Public"
label var year_financial "Financial Year for whcih the data is reported"

/*  Rename and label necessary/interesting variables*/

/* Drop unnecessary variables */
drop v* _merge

/* Save Recent Years' data */
save $health/nrhm_hmis/built/district_wise_health_data_all, replace


/**************************************/
/* Create state district matching key */
/**************************************/
use $health/nrhm_hmis/built/district_wise_health_data_all, clear
contract year state district

rename state hmis_state
rename district hmis_district
rename year hmis_year

/* Currently for 2017/18- 2019-2020 data, all years have same # of districts */
contract hmis_state hmis_district
save $health/nrhm_hmis/built/district_wise_health_data_all_key, replace


/******************************************************/
/* Merge HMIS district key with lgd pc11 district key */
/******************************************************/

/* import data */
use $health/nrhm_hmis/built/district_wise_health_data_all_key, clear

/* define programs to merge variables */
qui do $ddl/covid/covid_progs.do

/* gen hmis id */
gen hmis_id = hmis_state + "=" + hmis_district

/* format variables */
lgd_state_clean hmis_state
lgd_dist_clean hmis_district

/* merge */
lgd_state_match hmis_state
lgd_dist_match hmis_district

/* check dataset before saving */
order hmis_id, first

/* save matched dataset */
/* in temp folder for now, check before saving in data tree */
save $tmp/lgd_pc11_hmis_district_key, replace
