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

/* After loopig over the years macro:
1.Make directory for all the years
2.Convert XML Data into csv for all years using the .py script */
foreach year in `years'{
  cap mkdir $health/nrhm_hmis/built/`i'
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

 /**********************************************************************************/
 /* Loop through folders and append all .dta files across years into one .dta file */
 /* for new regime of data from 2017-2018 to 2019-2020                             */
 /**********************************************************************************/

/* Create a local again, just in case we run this part separately. */
local years "2017-2018 2018-2019 2019-2020"

/* Create temopfile to store all years' data */
clear
save $tmp/hmis_allyears, replace emptyok 

/* Loop over different years, and use tempfile to append all years' data into one file */
foreach year in `years'{
  use $health/nrhm_hmis/built/`year'/district_wise_health_data,clear
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

/* Save data */
save $health/nrhm_hmis/built/district_wise_health_data_all, replace

/**************************************/
/* Create state district matching key */
/**************************************/

contract year state district

rename state hmis_state
rename district hmis_district
rename year hmis_year

save $health/nrhm_hmis/built/district_wise_health_data_all_key, replace


/******************************************************/
/* Merge HMIS district key with lgd pc11 district key */
/******************************************************/

/* import data */
use $health/nrhm_hmis/built/district_wise_health_data_all_key, clear

/* format variables */
gen lgd_state_name = lower(hmis_state)
gen lgd_district_name = lower(hmis_district)

/* format state names for merge */
replace lgd_state_name = "andaman and nicobar islands" if hmis_state == "A & N Islands"
replace lgd_state_name = subinstr(lgd_state_name, "&", "and", .)

/* these districts are in ladakh in using data */
replace lgd_state_name = "ladakh" if inlist(lgd_district_name, "leh ladakh", "kargil")

/* format district names for merge */
replace lgd_district_name = subinstr(lgd_district_name, "paschim", "west", .)
replace lgd_district_name = subinstr(lgd_district_name, "purba", "east", .)
replace lgd_district_name = subinstr(lgd_district_name, "paschimi", "west", .)
replace lgd_district_name = subinstr(lgd_district_name, "purbi", "east", .)

/* extract lgd state names and ids */
merge m:1 lgd_state_name using $keys/lgd_pc11_state_key, gen(state_merge)
drop state_merge

/* fix lgd district name spellings */
fix_spelling lgd_district_name, src($keys/lgd_pc11_district_key.dta) group(lgd_state_name) replace

/* drop duplicates */
bys lgd_state_name lgd_district_name : keep if _n == 1
/* 3 duplicate obs dropped */

/* merge with lgd pc11 district key */
merge 1:1 lgd_state_name lgd_district_name using $keys/lgd_pc11_district_key, gen(hmis_lgd_merge)

/* save matched and unmatched obs separately */
savesome using $tmp/hmis_matched if hmis_lgd_merge == 3, replace
savesome using $tmp/hmis_unmatched if hmis_lgd_merge == 1, replace
savesome using $tmp/lgd_unmatched if hmis_lgd_merge == 2, replace

/* prep for masala merge */
use $tmp/hmis_unmatched, clear

/* generate ids */
gen idm = lgd_state_name + "=" + lgd_district_name

/* drop extra vars */
drop lgd_state_id - pc01_district_name *_merge

/* these obs were masala merging incorrectly */
replace lgd_district_name = "ayodhya" if hmis_district == "Faizabad"
replace lgd_district_name = "purbi champaran" if hmis_district == "East Champaran"

/* manual merges after checking unmatched output */
replace lgd_district_name = "y s r" if hmis_district == "Cuddapah"
replace lgd_district_name = "nuh" if hmis_district == "Mewat"
replace lgd_district_name = "kalaburagi" if hmis_district == "Gulbarga"
replace lgd_district_name = "east nimar" if hmis_district == "Khandwa"
replace lgd_district_name = "amethi" if hmis_district == "C S M Nagar"
replace lgd_district_name = "amroha" if hmis_district == "Jyotiba Phule Nagar"

/* save */
save $tmp/hmis_fmm, replace

use $tmp/lgd_unmatched, clear

/* generate ids */
gen idu = lgd_state_name + "=" + lgd_district_name

/* drop extra vars */
drop hmis_* _fre *_merge

/* save */
save $tmp/lgd_fmm, replace

/* prep using data for masala merge */
use $tmp/hmis_fmm, clear

/* merge */
masala_merge lgd_state_name using $tmp/lgd_fmm, s1(lgd_district_name) idmaster(idm) idusing(idu) minbigram(0.2) minscore(0.6) outfile($tmp/hmis_lgd)
drop lgd_district_name_master
ren lgd_district_name_using lgd_district_name

/* save matched separately */
savesome using $tmp/hmis_matched_r2 if match_source < 7, replace

/* append matched obs */
use $tmp/hmis_matched, clear
append using $tmp/hmis_matched_r2

/* clean up dataset */
drop masala* match_source idm idu *_merge

/* save matched dataset */
/* in temp folder for now, check before saving in data tree */
save $tmp/lgd_pc11_hmis_district_key, replace
