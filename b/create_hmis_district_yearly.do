/*

This do file processes and saves district level hmis data, through the following steps:

1. make directories for hmis data: to store and save intermediary files.
2. Ingest and Process District  Health/Itemwise Monthly Data
3. Process Number of Hospitals/data_reporting_status data
4. Merge Health and Hospital Data

Uutputs: $tmp/hmis/hmis_dist_clean_`year' for every financial year of hmis data

data source: https://nrhm-mis.nic.in/hmisreports/frmstandard_reports.aspx 

*/


/*************************************/
/* 1. make directories for hmis data */
/*************************************/
cap mkdir $tmp/hmis
cap mkdir $tmp/hmis/itemwise_monthly/
cap mkdir $tmp/hmis/itemwise_monthly/district
cap mkdir $tmp/hmis/itemwise_monthly/subdistrict
cap mkdir $tmp/hmis/data_reporting_status/

/*Unzip Health (itemwise monthly) Data */
foreach level in district subdistrict {
  local filelist : dir "$health/hmis/raw/itemwise_monthly/`level'/" files "*.zip"
  foreach file in `filelist' {
    !unzip -u $health/hmis/raw/itemwise_monthly/`level'/`file' -d $tmp/hmis/itemwise_monthly/`level'/
  }
}

/****************************************************************/
/* 2. Ingest and Process District  Health/Itemwise Monthly Data */
/****************************************************************/

/* Change directory to run python code */
cd $ddl/covid

/* Save all years in a local by Looping over all years in district directory*/
local years: dir "$tmp/hmis/itemwise_monthly/district/" dirs "*"

/* For every year of data: Convert every State's XML Data into csv using the .py script */
foreach year in `years'{
  shell python -c "from b.retrieve_hmis_data import read_hmis_csv; read_hmis_csv('`year'','$tmp')"
}

/* Save all years in a macro by Looping over all years in district directory*/
local years: dir "$tmp/hmis/itemwise_monthly/district/" dirs "*"

/* Save variable names and their description in separate key files */
foreach year in `years'{

  /* Read in saved variable definitions */
	import delimited using $tmp/hmis/itemwise_monthly/district/`year'/hmis_variable_definitions.csv, clear charset("utf-8")
	
	/* rename variable headers */
	ren v1 variable
	ren v2 description
	drop in 1

  /* Reformat variable names to be stata friendly */
  replace variable = subinstr(variable, "." , "_" , .)
  replace variable = subinstr(variable, "'", "", .)
  replace variable = subinstr(variable, " ", "_", .)
  replace variable = subinstr(variable, "(","_",.)
  replace variable = subinstr(variable, ")","",.)

	/* Save as stata file */
	save $health/hmis/data_dictionary/hmis_variable_definitions_`year', replace

}

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
  save $tmp/hmis/hmis_dist_clean_`year', replace
  
  /* Label the variables according to their data dictionary */
  /* read in variable definitions */
  import delimited using $tmp/hmis/itemwise_monthly/district/`year'/hmis_variable_definitions.csv, clear charset("utf-8")

  /* rename variable headers */
  ren v1 variable
  ren v2 description
  drop in 1

  /* Copy variable description as labels to variables encoded by in hmis_dist_clean_`year' */
  merge using $tmp/hmis/hmis_dist_clean_`year'
  drop _merge
  local i = 1
  foreach v of varlist v_* {
    local label = description[`i']
    label var `v' "`label'"
    local i = `i' + 1
  }
  
  /* Remove the variable and description fields in the main dataset from the data_dictionary */
  drop variable description
  
  /* Save labelled and cleaned data */
  save $tmp/hmis/hmis_dist_clean_`year', replace

}


/**************************************************************/
/* 3. Process Number of Hospitals/data_reporting_status data  */
/**************************************************************/
/* Unzip Hospitals/District Reporting Status Data from zip files and save .xls files in $tmp*/
local filelist : dir "$health/hmis/raw/data_reporting_status" files "*.zip"
foreach file in `filelist' {
  !unzip -u $health/hmis/raw/data_reporting_status/`file' -d $tmp/hmis/data_reporting_status
}

/* Change directory so you can reference the python script correctly */
cd $ddl/covid

/* Loop over all years to extract .xls(xml) files to csv */
local years: dir "$tmp/hmis/data_reporting_status" dirs "*-*"
foreach year in `years'{
  shell python -c "from b.retrieve_hmis_data import read_hmis_csv_hospitals; read_hmis_csv_hospitals('`year'','$tmp')"
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

/************************************/
/*4. Merge Health and Hospital Data */
/************************************/
foreach year in `years'{

  /* Use health data, merge with hospitals data and then save  */
  use $tmp/hmis/hmis_dist_clean_`year', clear
  merge 1:1 state district year month category year_financial using $tmp/hmis/hmis_dist_clean_hospitals_`year' 

  /* Drop unmerged hospitals data for 2020-2021  */
  /* Some 20 odd districts in 2015 are unmerged with hospital data
  due to changes in spelling */
  drop if _merge == 2
  drop _merge
  
  /* Save Merged health + hospitals data */
  save $tmp/hmis/hmis_dist_clean_`year', replace

}
