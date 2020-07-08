/*

This do file is to be run after district level hmis files have been run,
so essentially all the tmp folders creation, zip folder extraction has taken place.

We do the following in this :
1. Extract and group subdistrict level data at the state, and save state. csv files.
2. Append Variable Definitions for one year
3. Append All States' Data for one year
4. Label variables with their definitions

*/

/***********************************************/
/* 1. Extract and Group Subdistrict level data */
/***********************************************/
/* Extract and group subdistrict level data at the state, and save state. csv files.*/

/* Change directory to run python code */
cd $ddl/covid

/* Save all years in a local by Looping over all years in district directory*/
local years: dir "$tmp/hmis/itemwise_monthly/subdistrict/" dirs "*"

/* For every year of data: Convert every State's XML Data into csv using the .py script */
foreach year in `years'{
  shell python -c "from b.retrieve_case_data import read_hmis_subdistrict_csv; read_hmis_subdistrict_csv('`year'','$tmp')"
}


/***********************************************/
/* 2. Append Variable Definitions for one year */
/***********************************************/

/* Save all years in a local by Looping over all years in subdistrict directory*/
local years: dir "$tmp/hmis/itemwise_monthly/subdistrict/" dirs "*"

/* Read in variable definitions for all states in a year and append them, then remove duplicates */
foreach year in `years' {

  /* Read in variable definitions files for a year and store in local */
  local state_dict: dir "$tmp/hmis/itemwise_monthly/subdistrict/`year'/A.Monthwise" files "*hmis_variable_definitions.csv"
    
  /* Loop over all the variable defnition files and append them */

  /* Create a temp file to store all states' definitions */
  clear
  save $tmp/hmis_subdist_dict , replace emptyok
  foreach state in `state_dict'{

    /* import state wise variable data */
    import delimited using "$tmp/hmis/itemwise_monthly/subdistrict/`year'/A.Monthwise/`state'", clear charset("utf-8")

    /* Add thia state to previous states' data */
    append using $tmp/hmis_subdist_dict

    /* Only keep variable and description data (We have month and district as well, but for now, they're dropped */
    keep v2 v3
    rename v2 variable
    rename v3 description
    
    /* Drop 1st column */
    drop in 1
 
    /* Drop duplicates if any */
    duplicates drop
    
    /* Reformat variable names to be stata friendly */
		replace variable = subinstr(variable, "." , "_" , .)
		replace variable = subinstr(variable, "'", "", .)
    gen temp = regexs(1) if regexm("`varlabel'", "(^[^\ ]+)")
    local varlabel = temp 
    drop temp
    replace variable = subinstr(variable, "(","_",.)
		replace variable = subinstr(variable, ")","",.)
    
    /* Save Data */
    save $tmp/hmis_subdist_dict, replace
    
  }

  /* Drop missing data */
  drop if mi(variable)
  
  /* Save data */
  save $health/hmis/subdistrict/data_dictionary/hmis_variable_definitions_`year', replace
  
}


/*******************************************/
/* 3. Append All States' Data for one year */
/*******************************************/

/* Save all years in a local by Looping over all years in subdistrict directory*/
local years: dir "$tmp/hmis/itemwise_monthly/subdistrict/" dirs "*"

/* Loop through all years of data */
foreach year in `years' {
  di "current year is `year'"
  /* Append all the States' data */
  local filelist: dir "$tmp/hmis/itemwise_monthly/subdistrict/`year'/A.Monthwise" files "*.csv"  

  /* Create a temp file to hold all states; data for one paricular year */
  clear
  save $tmp/hmis_allstates, replace emptyok

  /* Loop through all state CSVs */
  foreach state in `filelist'{

    /* Import the state file` */
    import delimited "$tmp/hmis/itemwise_monthly/subdistrict/`year'/A.Monthwise/`state'", varn(1) clear
    
    
    /* Skip variable definitions */
    cap assert `c(k)' > 5
    if (_rc != 0) {
      di "`state' is not a state dataset, skipping"
      continue
    }

    /* generate a state and year variable */
    gen state = "`state'"
    gen year = "`year'"
  
    /* Remove .csv from state name */
    replace state = subinstr(state, ".csv", "", .)

    /* replace month as a numeric integer from 1-12 */
  	gen month_num = month(date(month,"M"))
  	
  	/*  put month name as value labels
  	(labutil has a useful function for this, hence the ssc install) */
  	//ssc install labutil
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
  	
      
    /* append to exiting states data */
    di "`state'"
    append using $tmp/hmis_allstates, force
    save $tmp/hmis_allstates, replace

  }

  /* Use appended all states data to work with(else the current dataset might be a variable definition csv) */
  use $tmp/hmis_allstates, clear
  
  /* bring identifying variables to the front */  
  /* For  years 2017-2021, where the variable "category" exists*/
  capture confirm variable category
  if (_rc == 0){ 
    order state district year month category year_financial
  }
  
  /* For years 2008-2017, where the variable "category" doesn't exist
  we create a category variable here and set it equal to total.*/
  capture confirm variable category
  if (_rc != 0){
    /* We assume data reported is total since no  private/public or urban/rural here */
    gen category = "Total [(A+B) or (C+D)]"
    order state district year month category year_financial
  }
  
  /* Drop (possibly) index variable */
  drop v1

  /* Label the variable names properly */
  foreach v of varlist v* {
    local varlabel : variable label `v'
    local varlabel = subinstr("`varlabel'", "." , "_" , .)
    local varlabel = subinstr("`varlabel'", "'", "", .)
    gen temp = regexs(1) if regexm("`varlabel'", "(^[^\ ]+)")
    local varlabel = temp 
    drop temp
    local varlabel = subinstr("`varlabel'", "(","_",.)
    local varlabel = subinstr("`varlabel'", ")","",.)
    local varlabel = subinstr("`varlabel'", "_$", "",.)
    rename `v'  v_`varlabel'
  }

  /* Remove the underscore at end of variable names */
  ren (*_) (*)
  
  /* Save data */
  save $tmp/hmis/subdistrict/hmis_subdist_clean_`year', replace
  
}


/*********************************************/
/* 4. Label variables with their definitions */
/*********************************************/

/* Save all years in a local by Looping over all years in subdistrict directory*/
local years: dir "$tmp/hmis/itemwise_monthly/subdistrict/" dirs "*"

/* Loop through all years of data */
foreach year in `years' {
  /* read in variable definitions */
  use $health/hmis/subdistrict/data_dictionary/hmis_variable_definitions_`year', clear  
  
  /* Copy variable description as labels to variables encoded by in hmis_dist_clean_`year' */
  merge using $tmp/hmis/subdistrict/hmis_subdist_clean_`year'
  drop _merge
  local i = 1
  foreach v of varlist v_* {
    local label = description[`i']
    label var `v' "`label'"
    local i = `i' + 1
  }
  
  /* Remove the variable and description fields in the main dataset from the data_dictionary */
  drop variable description

  /* Save Data */
  save $tmp/hmis/subdistrict/hmis_subdist_clean_`year', replace

}
 
