/*

This code creates a key to merge hmis data with pre-existing pc11_lgd keys in the follwowing steps:
1. Create a key from hmis subdstrict data 
2. Merge HMIS district key with lgd pc11 district key 
3. Masala Merge Using Subdistrict Key
4. Masala Merge Unmatched Subdistrict Matches with Block Key
5. Append and Save all matched data and then add in unmatched data

Pending Issues:
1. We match about 70% of all subdistricts over all years.
2. Not all lgd subdistricts have pc11 counterparts. This needs to be fixed in the lgd_pc11 match
3. The district key used to match with the subdistrict data has some Andhra Pradesh/Telangana errors
the origin of which neeed to be checked out for the 511 subdistricts that don't match.

*/

/**********************************************/
/* 1. Create a key from hmis subdstrict data  */
/**********************************************/
/* Use hmis subdistrict dataset to create key on identifiers*/
use $health/hmis/hmis_subdist_clean, clear
contract year_financial state district subdistrict

/* Rename Variables for merge clarity*/
rename state hmis_state
rename district hmis_district
rename subdistrict hmis_subdistrict
rename year_financial hmis_year

/* Save hmis key  */
save $tmp/hmis/hmis_subdist_clean_key, replace

/********************************************************/
/*2. Merge HMIS district key with lgd pc11 district key */
/********************************************************/

/* Read in hmis_subdist_key */
use $health/hmis/hmis_subdist_clean_key.dta, clear

/* Get a macro of all years */
levelsof hmis_year, local(year_financial)

/* Create empty file to append all data too */
clear
save $tmp/append_keys, emptyok replace

/* Loop over all financial years' data */
foreach year in `year_financial' {

	/* Merge district Key with subdistrict key */
	use $health/hmis/hmis_district_key.dta, clear
	/* Fix Telangana and Andhra Pradesh Mismatches */
	merge 1:m hmis_state hmis_district hmis_year using $health/hmis/hmis_subdist_clean_key.dta, keepusing(hmis_state hmis_district hmis_subdistrict hmis_year)
	keep if _merge ==3
	drop _merge


/****************************************/
/*3. Masala Merge Using Subdistrict Key */
/****************************************/
  keep if hmis_year == "`year'"
  gen lgd_subdistrict_name = lower(hmis_subdistrict)
  gen idm = hmis_state + "=" + hmis_district + "=" + hmis_subdistrict
  
  masala_merge lgd_state_id lgd_district_id using $keys/lgd_pc11_subdistrict_key, ///
      s1(lgd_subdistrict_name) idmaster(idm) idusing(lgd_subdistrict_id) 
  
  /* Drop irrelevant variables */
  drop lgd_subdistrict_name_master  lgd_subdistrict_name_local 
  
  /* Rename subdistrct names from lgd data */
  ren lgd_subdistrict_name_using lgd_subdistrict_name
  
  /* Save type of merge(Matched with Subdistrict key) */
  gen merge_type = "Subdistrict Key" if _merge == 3
  
  /* Save matched names */
  savesome using $tmp/subdistrict_masala_matched  if _merge == 3, replace
  
  /* Save unmerged names from hmis_key */
  savesome using $tmp/subdistrict_masala_unmatched  if _merge == 1, replace

/****************************************************************/
/* 4. Masala Merge Unmatched Subdistrict Matches with Block Key */
/****************************************************************/

//Skip for 2008-2009, nothing to merge here.
  if ("`year'" != "2008-2009"){
	  /* Use unmatched names */
	  use $tmp/subdistrict_masala_unmatched, clear
	  
	  /* Drop variables not required for block masala merge */
	  drop lgd_subdistrict* pc11* _merge match_source masala_dist
	  
	  /* Generate block name variable to merge with block key */
	  gen lgd_block_name = lower(hmis_subdistrict)
	  
	  /* Masala Merge with lgd_pc11 block key */
	  masala_merge lgd_state_id lgd_district_id using $keys/lgd_pc11_block_key, ///
	      s1(lgd_block_name) idmaster(idm) idusing(lgd_block_id)
	
		/* Drop names and rename them to be consistent with Subdistrct Key Masala Merge */
		drop lgd_block_name_master 
		rename lgd_block_name_using lgd_block_name
		
		/* Save Merge Type */
		replace merge_type = "Block Key" if _merge == 3
		
		/* Save matched block data */
		savesome using $tmp/block_masala_matched if _merge == 3, replace
		
		/* Save unmatched block data */
		savesome using $tmp/block_masala_unmatched if _merge == 1, replace

  
  
/**********************************************************************/
/* 5. Append and Save all matched data and then add in unmatched data */
/**********************************************************************/
    /* Use Block Merged Data */
    use $tmp/block_masala_matched, clear

    /* Append Subdistrict Matches */
    append using $tmp/subdistrict_masala_matched 

    /* Append unmatched data even after block matching */
    append using $tmp/block_masala_unmatched

    /* Order variables */
    order *_state* *_district* *_subdistrict* *_block* 
    order hmis* lgd* pc11*


  }

  /* Save the particular years' keys */
  append using $tmp/append_keys  
  save $tmp/append_keys, replace
}

/* Drop empty values that come feom 2008-2009 handling */
drop if _merge == 2

/* Save Data */
save $health/hmis/hmis_subdistrict_key, replace 
