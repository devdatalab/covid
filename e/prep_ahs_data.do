/* Structure and clean the AHS CAB and COMB (household) data
1. Structure the CAB and COMB data
2. Clean the COMB (household) data
3. Clean the CAB (health) data
4. Merge the CAB and COMB data
 */

/**********************************/
/* 1. Structure CAB and COMB Data */
/**********************************/
/* Note that due to the time it takes to read in the excel files, this section may take 1-2 hours */

/* initiate empty files for each */
cap mkdir $tmp/ahs
clear
save $tmp/ahs/ahs_cab, emptyok replace
save $tmp/ahs/ahs_comb, emptyok replace
save $tmp/ahs/ahs_mort, emptyok replace
save $tmp/ahs/ahs_woman, emptyok replace
save $tmp/ahs/ahs_wps, emptyok replace

/* CAB DATA */
foreach state in 05 08 09 10 18 20 21 22 23 {
  
  /* read in the data */
  import delimited $health/ahs/raw/cab/`state'.csv, delimit("|") clear

  /* rename  state and district if needed */
  cap ren state_code state
  cap ren district_code district

  /* convert state and district codes to standard format */
  tostring state, format("%02.0f") replace
  tostring district, format("%03.0f") replace

  /* drop if the state code is not correct (this catches some data entry errors that disrupts appending) */
  drop if state != "`state'"

  /* correct the format of rural_urban indicator */
  cap destring rural_urban, replace
  compress state district
    
  /* append to full file */
  append using $tmp/ahs/ahs_cab, force

  /* resave full file */
  save $tmp/ahs/ahs_cab, replace    
}

/* COMB DATA */
foreach state in 05 08 09 10 18 20 21 22 23 {
  
  /* read in the data */
  import delimited $health/ahs/raw/comb/`state'.csv, delimit("|") clear

  /* convert state and district codes to standard format */
  tostring state, format("%02.0f") replace
  tostring district, format("%03.0f") replace

  /* standardize data types to match across states, cleaning corrupted entries*/
  tostring hh_id client_hh_id hl_id member_identity, replace
  destring currently_dead_or_out_migrated sex usual_residance relation_to_head father_serial_no mother_serial_no date_of_birth ///
           month_of_birth year_of_birth age religion social_group_code marital_status date_of_marriage date_of_marriage year_of_marriage month_of_marriage ///
           currently_attending_school reason_for_not_attending_school highest_qualification occupation_status diagnosed_for diagnosis_source ///
           regular_treatment regular_treatment_source chew smoke alcohol hh_expall_status client_hl_id serial_no house_status house_structure ///
           owner_status drinking_water_source water_filteration household_have_electricity lighting_source cooking_fuel no_of_dwelling_rooms kitchen_availability ///
           cart land_possessed hl_expall_status isdeadmigrated residancial_status iscoveredbyhealthscheme healthscheme_1 healthscheme_2 housestatus householdstatus isheadchanged ///
           fid fidh wt fidx rtelephoneno recordupdatedcount recordstatus is* symptoms_pertaining_illness disability_status injury_treatment_type ///
           illness_type treatment_source sought_medical_care status toilet_used month_of_marriage hh_serial_no hh_serial_no as_binned, replace force

  /* drop missing values of key indicators, created by destring */
  drop if mi(sex)
  drop if (year != 1 & year != 2 & year != 3)
  
  /* append to full file */
  append using $tmp/ahs/ahs_comb

  /* resave full file */
  save $tmp/ahs/ahs_comb, replace    
}

/**************************/
/* 2. Clean the COMB data */
/**************************/

/* open the ahs household data */
use $tmp/ahs/ahs_comb, clear

/* keep only if there is data from the correct round on diagnoses */
keep if year == 3 

/* drop if missing fid as these entries have no data */
drop if mi(fid)

/* rename variables to match the cab dataset */
ren stratum_code stratum
ren house_no ahs_house_unit
ren member_identity identification_code
ren hh_serial_no sl_no

/* convert identification code to numeric */
destring identification_code, replace

/* drop any entries with missing identifying information - this is done in Jung et al. as well */
drop if mi(state) | mi(district) | mi(stratum) | mi(ahs_house_unit) | mi(house_hold_no) | mi(sl_no) | mi(identification_code) 

/* drop all duplicates so data can be merged */
ddrop state district stratum ahs_house_unit house_hold_no sl_no identification_code

/* rename hh variables to check the merge */
ren year_of_birth year_of_birth_comb
ren sex sex_comb
ren age age_comb
ren usual_residance usual_residance_comb

/* save as a temporary file for merging */
save $tmp/ahs_comb_formerge, replace

/*************************/
/* 3. Clean the CAB data */
/*************************/
/* open the AHS cab file */
use $tmp/ahs/ahs_cab, clear

/* convert age to be given as years */
replace age = 0 if age_code == "M" | age_code == "m" | age_code == "D" | age_code == "d"

/* clean the survey date string */
replace date_survey = subinstr(date_survey, "/1914", "/2014", .)
replace date_survey = subinstr(date_survey, "/2003", "/2013", .)

/* create date object for the survey date */
gen sdate = date(date_survey, "DMY")

/* clean the date and month of birth- assume 0 is 1 */
replace month_of_birth = 1 if month_of_birth == 0
replace date_of_birth = 1 if date_of_birth == 0

/* for nonexistant dates, (i.e. nov 31), replace the date with the last date in the month */
replace date_of_birth = 30 if (date_of_birth > 30) & (month_of_birth == 4 | month_of_birth == 6 | month_of_birth == 9 | month_of_birth == 11)
replace date_of_birth = 28 if (date_of_birth > 28) & (month_of_birth == 2)

/* create a date object for the date of birth */
gen bdate = mdy(month_of_birth, date_of_birth, year_of_birth)

/* calculate the age as a difference between the survey and birth date */
gen int age_calc = (sdate - bdate) / 365

/* mark if indiviudal is pregnant */
gen pregnant = 1 if gauna_perfor_not_perfor == 1
replace pregnant = 0 if sex == 1 | inlist(gauna_perfor_not_perfor, 2, 3)

/* drop any entries with missing identifying information */
drop if mi(state) | mi(district) | mi(stratum) | mi(ahs_house_unit) | mi(house_hold_no) | mi(sl_no) | mi(identification_code)

/* drop all duplicates so data can be merged */
ddrop state district stratum ahs_house_unit house_hold_no sl_no identification_code 

/******************************/
/* 4. Merge CAB and COMB data */
/******************************/

/* merge in some variables from the household data */
merge 1:1 state district stratum ahs_house_unit house_hold_no sl_no identification_code using $tmp/ahs_comb_formerge, keepusing(illness_type illness_type diagnosed_for sex_comb year_of_birth_comb age_comb usual_residance_comb)

/* keep the master (cab-only) and matched (cab + hh) data */
ren _merge ahs_merge
cap label define ahs_merge 1 "cab only" 2 "comb only" 3 "cab + comb"
label values ahs_merge ahs_merge

/* rename bp variables */
ren bp_systolic bp_systolic_1_reading
ren bp_diastolic bp_diastolic_1_reading
ren bp_diastolic_2reading bp_diastolic_2_reading

/* clean missing values in the AHS */
foreach var in weight_in_kg length_height_cm age haemoglobin_level bp_systolic_1_reading bp_systolic_2_reading bp_diastolic_1_reading bp_diastolic_2_reading pulse_rate pulse_rate_2_reading fasting_blood_glucose_mg_dl first_breast_feeding is_cur_breast_feeding illness_type treatment_type illness_duration{
  replace `var' = . if `var' == -1
}

/* convert state and dist codes to byte to match key */
destring state, replace
ren district dist
destring dist, replace

/* merge in pc11 id from key */
merge m:1 state dist using $health/dlhs/dlhs4_district_key, keepusing(pc11_state_id pc11_district_id pc11_state_name) keep(match master) nogen

/* convert identifying information into standard string lengths */
tostring identification_code, format("%05.0f") replace
tostring house_hold_no, format("%03.0f") replace
tostring ahs_house_unit, format("%04.0f") replace
tostring sl_no, format("%05.0f") replace

/* create a unique identifying index for the ahs data */
egen index = concat(state dist stratum ahs_house_unit house_hold_no sl_no identification_code), 

/* save in permanent ahs folder */
save $health/ahs/ahs_cab, replace
