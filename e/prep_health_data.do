/* This file preps AHS and DLHS data

1. structure AHS data, combine by state
2. structure DLHS data, combine by state
4. merge with PC11 state and district codes
*/

/*************************/
/* 1. Structure AHS data */
/************************/

/* initiate empty files for each */
cap mkdir $tmp/ahs
clear
save $tmp/ahs/ahs_cab, emptyok replace
save $tmp/ahs/ahs_comb, emptyok replace
save $tmp/ahs/ahs_mort, emptyok replace
save $tmp/ahs/ahs_woman, emptyok replace
save $tmp/ahs/ahs_wps, emptyok replace

/* cycle through each file type */
foreach type in cab comb mort woman wps {

  /* cycle through states */
  foreach state in 05 08 09 10 18 20 21 22 23 {
  
    /* read in the data */
    import delimited $health/ahs/raw/`type'/`state'.csv, delimit("|") clear

    /* convert state and district codes to standard format */
    tostring state_code, format("%02.0f") replace
    tostring district_code, format("%03.0f") replace

    /* drop if the state code is not correct (this catches some data entry errors that disrupts appending) */
    drop if state_code != "`state'"

    /* correct the format of rural_urban indicator */
    destring rural_urban, replace
    compress state_code district_code rural_urban
    
    /* append to full file */
    append using $tmp/ahs/ahs_`type', force

    /* resave full file */
    save $tmp/ahs/ahs_`type', replace    
  }
}

/**************************/
/* 2. Structure DLHS data */
/**************************/

/* initiate empty files for each  */
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
  local filelist: dir "$health/dlhs/raw/`state'" files "*.dta"

  /* cycle through the data files for this state */
  foreach file in `filelist' {

    /* extract the name of this file */
    tokenize "`file'" , parse("_")
    local var = "`3'"
    
    /* open the file */
    use $health/dlhs/raw/`state'/`file', clear

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
/* 3. Match with PC11 codes */
/****************************/
/* 05/19/20 - for now this only deals with the cab data */

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

/* save in permanent dlhs folder */
save $health/dlhs/dlhs_cab, replace

/* open the AHS data file */
use $tmp/ahs/ahs_cab, clear

/* clean missing values in the AHS */
foreach var in weight_in_kg length_height_cm age haemoglobin_level bp_systolic bp_systolic_2_reading bp_diastolic bp_diastolic_2reading pulse_rate pulse_rate_2_reading fasting_blood_glucose_mg_dl first_breast_feeding is_cur_breast_feeding illness_type treatment_type illness_duration{
  replace `var' = . if `var' == -1
}

/* rename bp variables */
ren bp_systolic bp_systolic_1_reading
ren bp_diastolic bp_diastolic_1_reading
ren bp_diastolic_2reading bp_diastolic_2_reading

/* convert state and dist codes to byte to match key */
destring state_code, gen(state)
destring dist, gen(dist)

/* merge in pc11 id from key */
merge m:1 state dist using $health/dlhs/dlhs4_district_key, keepusing(pc11_state_id pc11_district_id) keep(match master) nogen

/* save in permanent ahs folder */
save $health/ahs/ahs_cab, replace
