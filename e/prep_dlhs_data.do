/* This file preps DLHS Data
1. structure DLHS data, combine by state
2. merge with PC11 state and district codes
*/

/**************************/
/* 1. Structure DLHS data */
/**************************/

/* initiate empty files for each */
cap mkdir $tmp/dlhs
clear
save $tmp/dlhs/dlhs_BIRTH, emptyok replace
save $tmp/dlhs/dlhs_cab, emptyok replace
save $tmp/dlhs/dlhs_HOUSEHOLD, emptyok replace
save $tmp/dlhs/dlhs_IMMU, emptyok replace
save $tmp/dlhs/dlhs_marriage, emptyok replace
save $tmp/dlhs/dlhs_person, emptyok replace
save $tmp/dlhs/dlhs_village, emptyok replace
save $tmp/dlhs/dlhs_WOMAN, emptyok replace

/* combine state data for each file type */
local statelist Andaman_Nicobar AndhraPradesh ArunachalPradesh Chandigarh GOA Haryana HimachalPradesh Karnataka Kerala Maharashtra Manipur Meghalaya Mizoram Nagaland Puducherry Punjab Sikkim TamilNadu Telangana Tripura WestBengal

/* cycle through all states with dlhs data */
foreach state in `statelist' {

  /* get the list of files in the state folder */
  local filelist: dir "$health/dlhs/raw/`state'" files "*cab.dta"

  /* cycle through the data files for this state */
  foreach file in `filelist' {

    /* extract the name of this file */
    tokenize "`file'" , parse("_")
    local var = "`3'"
    
    /* open the file */
    use $health/dlhs/raw/`state'/`file', clear
    qui count
    local counter = `counter' + `r(N)'

    /* save the state name */
    gen state_name = "`state'"
    replace state_name = lower(state_name)

    /* append to the full file */
    append using $tmp/dlhs/dlhs_`var'

    /* resave full file */
    save $tmp/dlhs/dlhs_`var', replace
  }
}


/****************************/
/* 2. Match with PC11 codes */
/****************************/
/* 05/19/20 - for now this only deals with the cab data, merging in some hh variables from ahs_comb */

/* open the DLHS data file, clean and save */
use $tmp/dlhs/dlhs_cab, clear

/* clean state names to match pc11_state_name */
gen pc11_state_name = state_name
replace pc11_state_name = subinstr(pc11_state_name, "pradesh", " pradesh", .)
replace pc11_state_name = "andaman nicobar islands" if pc11_state_name == "andaman_nicobar"
replace pc11_state_name = "tamil nadu" if pc11_state_name == "tamilnadu"
replace pc11_state_name = "andhra pradesh" if pc11_state_name == "telangana"
replace pc11_state_name = "west bengal" if pc11_state_name == "westbengal"

/* merge in pc11 id from key */
merge m:1 pc11_state_name dist using $health/dlhs/dlhs4_district_key, keepusing(pc11_state_id pc11_district_id) keep(match master) nogen

/* Basic Cleaning */
/* drop 14,076 records from Karnataka that have all data fields missing */
drop if mi(psu)

/* drop duplicates - force these to drop as these are all duplicated records but won't 
   get dropped with a simple duplicates drop because of missing values */
duplicates drop primekeynew, force

/* rename the primekeynew to be an index for DLHS */
ren primekeynew index

/* create pregnancy indicator */
gen pregnant = 1 if !mi(hv81) & (hv81 == 1 | hv81 == 2)
replace pregnant = 0 if mi(pregnant)

/* save in permanent dlhs folder */
save $health/dlhs/dlhs_cab, replace
