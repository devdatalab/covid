/*********************************************************/
/* Create year state district matching key for hmis data */
/*********************************************************/

/* Use hmis small dataset to create key on identifiers*/
use $health/hmis/hmis_dist_clean, clear
contract year_financial state district

/* Rename Variables for merge clarity*/
rename state hmis_state
rename district hmis_district
rename year_financial hmis_year

/* Save hmis key  */
save $tmp/hmis/hmis_dist_clean_key, replace

/******************************************************/
/* Merge HMIS district key with lgd pc11 district key */
/******************************************************/

/* Create empty tmp file to store all years' keys*/
clear
save $tmp/append_keys, replace emptyok

/* define programs to merge variables */
qui do $ddl/covid/covid_progs.do

/* Import data to get distinct values to loop over */
use $tmp/hmis/hmis_dist_clean_key, clear

/* Get distinct values of hmis_year variable */
levelsof hmis_year, local(fin_years)

foreach year in `fin_years'{
  
  /* import data */
  use $health/hmis/hmis_dist_clean_key, clear

  /* Filter current financial years' data */
  keep if hmis_year == "`year'"
  
	/* gen hmis state and district name vars */
	gen hmis_state_name = hmis_state
	gen hmis_district_name = hmis_district
		
	/* format variables */
	lgd_state_clean hmis_state
	lgd_dist_clean hmis_district
	
	/* merge */
	lgd_state_match hmis_state
	lgd_dist_match hmis_district

	/* ren hmis vars */
	ren (hmis_state_name hmis_district_name) (hmis_state hmis_district)

  /* Gen HMIS Years */
  gen hmis_year = "`year'"
  
  /* Append and Save Data */
  append using $tmp/append_keys
  save $tmp/append_keys, replace

}

/* save matched dataset */
save $health/hmis/hmis_district_key, replace

