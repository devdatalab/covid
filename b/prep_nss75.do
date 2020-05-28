/*
		Uses NSS 75th Round 2017-18 Health Modules
		- designed to be representative at the state rural/urban level
		- 133,823 HH; 557,888 individuals (555,351 living, 2,537 dead)
		- 36 states (includes Telengana but not Ladakh)
		- 648 districts; district codes are serial numbers unique within state
		
		NSS records for all individuals
		- any illness in 15days + details of illness condition and type of care sought conditional on illness 
		- any hospitalization in 1yr + details of illness condition and type of hospital conditional on hospitalization. 
		
		This do file links NSS HH-level, individual-level, and illness-episode and hospitalization-episode level modules.
		It then generates district level rural/urban male/female estimates of
		- population illness incidence (overall and for key illnesses)
		- population hospitalization incidence (overall and for key illnesses)
		- whether any medical care sought for illness and facility-type shares of care-seeking conditional on any care (excluding childbirth)
		- hospital-type shares, excluding childbirth, conditional on any hospitalization (excluding childbirth)
*/	

/* install necessary functions */
ssc install labutil

*SET FILE PATH 
**************************************************************************************************************	
global nss75 $nss/nss-75-health
cap mkdir $tmp/nss75

**************************************************************************************************************	
*PREPARE PC11 CODES
**************************************************************************************************************	
use $keys/lgd_state_key, clear
keep lgd_state_id lgd_state_name 
gen state = lgd_state_id 
rename lgd_state_name state_name 
lab var lgd_state_id "LGD State ID"
duplicates drop 
destring *, replace
save $tmp/nss75/lgd_state_key, replace

**************************************************************************************************************	
*COLLATE RAW NSS DATA	
**************************************************************************************************************	

**************************************************************************************
*HOUSEHOLD CHARACTERISTICS
**************************************************************************************
use $nss75/Lev02, clear
*133,823 HH observations

keep state district hhid w1 w mlt nsc nss sector 
destring *  , replace

*Merge in LGD state codes and standardized names
ren (state district) (nss_state_id nss_district_id)
//merge m:1 nss_state_id nss_district_id using $nss75/nss75_lgd_district_key, keep(1 3) nogen
//
//rename state state_code			
//labmask state_code, val(state_name)
//lab var state_name "State"
//lab var state_code "State code"
//lab var district "District NSS code"

gen urban = sector==2
cap lab def urban 1 "Urban" 0 "Rural"
lab val urban urban 
lab var urban "Urban"
drop sector

*Weights 
gen weight = mlt/nss if nss==nsc
replace weight = mlt/200 if nss!=nsc
drop nss nsc mlt w w1

save $tmp/nss75/hh, replace


**************************************************************************************
*HOUSEHOLD ROSTER
**************************************************************************************
*LIVING ROSTER
****************
use $nss75/Lev03, clear
*555,351 indiv observations
*Note: total of "hhsize" variable in HH chars is 555,115; "female members from other HH for whom major share of childbirth expenses borne by HH" are included in roster but not in hhsize

keep hhid personid sex age hospitalised chronic ailment ailment_day 
destring *, replace 

*Calculating illness incidence using only living HH roster per NSS documentation (later we find illness details for dead as well, but sticking with official)
*237 individuals (female widows) have ailment and chronic questions missing in Roster and are unmatched in care details, so assuming zero values for illness
recode ailment chronic ailment_day (2=0) (.=0)			
egen i15_illany = rowmax(ailment chronic ailment_day)
lab var i15_illany "Any illness in 15d"
drop ailment chronic ailment_day

save $tmp/nss75/roster, replace

*DEAD ROSTER
****************
use $nss75/Lev04, clear						
*2,537 indiv observations 

keep hhid personid sex death_age hosp 
rename (death_age hosp) (age hospitalised)
destring *, replace 

*APPEND DEAD TO LIVING AND CLEAN UP ROSTER
********************************************
*Append dead to living people within HH roster
append using $tmp/nss75/roster
bys personid: assert _N==1

gen female = sex==2 if sex!=.
cap lab def fem 0 "Male" 1 "Female"
lab val female fem 
lab var female "Female"
drop sex

recode hospitalised (2=0)
rename hospitalised h365_hospany
lab var h365_hospany "Any hospital visit in 1yr"

*Merge HH variables in
merge m:1 hhid using $tmp/nss75/hh, nogen
save $tmp/nss75/roster, replace 

**************************************************************************************
*DETAILS OF CARE FOR AILMENTS IN LAST 15 DAYS (PREFIX: i15_)
**************************************************************************************
use $nss75/Lev08, clear
*43,240 illness observations; 39,902 indivs 

keep hhid personid ailment_nature care_level7 
destring * , replace

*Illness conditions
gen fever = ailment_nature>=1 & ailment_nature<=4 		
gen tb = ailment_nature==5
gen cancer = ailment_nature==13
gen diabetes = ailment_nature==16
gen hypertension = ailment_nature==34
gen heart = ailment_nature==35
gen respiratory = ailment_nature>=36 & ailment_nature<=38

*Indicator for childbirth - to be excluded from care-seeking stats but leaving these indivis in for illness incidence denominator
gen childbirth = ailment_nature>=87 & ailment_nature<=89 

*ILLNESS LEVEL CARE-SEEKING VARIABLES (FOR FACILITY TYPE SHARES)
*****************************************************************
*Sought any care for non-obstetric condition 
gen i15_anycare = care_level7!=. if childbirth!=1
lab var i15_anycare "Any medical care for non-obstetric illness in 15dys"

*Provider type conditional on seeking care for non-obstetric condition
*Breakdown of provider type (care_level7): 1 "Public hospital/health center" 2 "Charitable hospital" 3 "Private hospital" 4 "Private clinic" 5 "Informal provider"
gen i15_pub = care_level7==1 if i15_anycare==1
gen i15_pvthosp = care_level7==2 | care_level7==3 if i15_anycare==1
gen i15_pvtclinic = care_level7==4 | care_level7==5 if i15_anycare==1
lab var i15_pub "Pub hospital/health center share of medical care for non-obstetric illness in 15dys"
lab var i15_pvthosp "Private hospital share of medical care for non-obstetric illness in 15dys"
lab var i15_pvtclinic "Private clinic/informal provider share of medical care for non-obstetric illness in 15dys"

*Save dataset at care-seeking level 
preserve
keep hhid personid i15_*
save $tmp/nss75/i15_care, replace
restore	

*INDIVIDUAL LEVEL ILLNESS VARIABLES (FOR POPULATION INCIDENCE)
**************************************************************
*Dummies for any non-obstetric illness and different types of illness (for population illness incidence)
gen i15_illnonobstetricany = childbirth!=1
lab var i15_illnonobstetricany "Any non-obstetric illness in 15dys"

local vars fever tb cancer diabetes hypertension heart respiratory 
local labels `" "Fever" "TB" "Cancer" "Diabetes" "Hypertension" "Heart condition" "Respiratory condition" "'
local count : word count `vars'
forval i=1/`count' {
  local var : word `i' of `vars'
  local label : word `i' of `labels'
  egen i15_`var'_any = max(`var'), by(personid)
  lab var i15_`var'_any "Any `label' in 15dys"
}

*Save dataset at individual level for illness incidence 
keep hhid personid i15_*any 
duplicates drop hhid personid, force

save $tmp/nss75/i15_ill, replace

**************************************************************************************
*DETAILS OF EACH HOSPITALISATION IN LAST 365 DAYS (PREFIX: h365_)
**************************************************************************************
use $nss75/Lev05, clear
*93,925 hospital observations; 87,310 indivs 

keep hhid personid hosp_slno ailment_nature med_institution
destring *, replace 

*Illness type (conditional on hospitalization)
gen fever = ailment_nature>=1 & ailment_nature<=4 		
gen tb = ailment_nature==5
gen cancer = ailment_nature==13
gen diabetes = ailment_nature==16
gen hypertension = ailment_nature==34
gen heart = ailment_nature==35
gen respiratory = ailment_nature>=36 & ailment_nature<=38

*Indicator for childbirth - to be excluded from care-seeking stats 
gen childbirth = ailment_nature>=87 & ailment_nature<=89 


*HOSPITAL LEVEL CARE-SEEKING VARIABLES (FOR FACILITY TYPE SHARES)
****************************************************************
*Hospital type
*Breakdown of hospital type (med_institution): 1 "Public" 2 "NGO" 3 "Private"
gen h365_pubhosp = med_institution ==1 if childbirth!=1
gen h365_pvthosp = med_institution ==2 if childbirth!=1
gen h365_ngohosp = med_institution ==3 if childbirth!=1
lab var h365_pubhosp "Public hospital share of non-obstetric hospital visits in 1yr"
lab var h365_pvthosp "Private hospital share of non-obstetric hospital visits in 1yr"
lab var h365_ngohosp "NGO hospital share of non-obstetric hospital visits in 1yr"

*Save dataset at care-seeking level 
preserve
keep hhid personid h365_*			
save $tmp/nss75/h365_care, replace
restore

*INDIVIDUAL LEVEL HOSPITALIZATION VARIABLES (FOR POPULATION HOSPITALIZATION INCIDENCE)
******************************************************************************************
*Any non-obstetric hospitalization (for population hospitalization incidence)
gen h365_hospnonobstetricany = childbirth!=1
lab var h365_hospnonobstetricany "Any non-obstetric hospital visit in 1yr"

*Any hospitalization for key illnesses (for population hospitalization incidence by illness)
local count : word count `vars'
forval i=1/`count' {
  local var : word `i' of `vars'
  local label : word `i' of `labels'
  egen h365_`var'any = max(`var'), by(personid)
  lab var h365_`var'any "Hospital visit for `label' in 1yr"
}

*Save dataset at individual level for hospitalized illness incidence 
keep hhid personid h365_*any 
duplicates drop hhid personid, force 

save $tmp/nss75/h365_ill, replace


**************************************************************************************
*COLLAPSE TO DISTRICT LEVEL 
**************************************************************************************

*MERGE AND COLLAPSE INDIVIDUAL LEVEL ILLNESS AND HOSPITALIZATION INCIDENCE DATASETS
************************************************************************************
use $tmp/nss75/roster, clear
merge m:1 hhid personid using $tmp/nss75/i15_ill, nogen
merge 1:1 hhid personid using $tmp/nss75/h365_ill, nogen

*Add zeroes for non-ill individuals for population incidence
foreach v of varlist i15*_any {
  replace `v' = 0 if `v'==.
}

*DATA CHECK: THIS REPLICATES TABLE A1 in NSS REPORT: Share population reporting any ailment in 15days by state rural/urban 
*table state_na urban [aw=w], c(mean i15_illany) row col 		

*Collapse to district level 
collapse_save_labels
collapse (mean) i15_*any h365_*any [aw=weight], by(nss_state_id nss_district_id urban female)
collapse_apply_labels

save $tmp/nss75/districtdata, replace


*COLLAPSE AND MERGE IN ILLNESS FACILITY TYPE SHARES
***************************************************
use $tmp/nss75/roster, clear
merge 1:m hhid personid using $tmp/nss75/i15_care, nogen

*DATA CHECK: THIS REPLICATES TABLE A7 in NSS REPORT: Share ailments treated and public facility share of treatments (but excludes childbirth so slight differences)
*table urban female [aw=w], c(mean i15_anycare mean i15_pub) row col

*Collapse to district level 
collapse_save_labels
collapse (mean) age i15_* [aw=weight], by(nss_state_id nss_district_id urban female)
collapse_apply_labels

merge 1:1 nss_state_id nss_district_id urban female using $tmp/nss75/districtdata, nogen
save $tmp/nss75/districtdata, replace

*COLLAPSE AND MERGE IN HOSPITALIZATION FACILITY TYPE SHARES
**********************************************************
use $tmp/nss75/roster, clear
merge 1:m hhid personid using $tmp/nss75/h365_care, nogen

*DATA CHECK: THIS REPLICATES TABLE A13 in NSS REPORT: Share of non-childbirth hospitals by type of hospital
*table state_na urban [aw=w], c(mean h365_pubhosp mean h365_pvthosp mean h365_ngohosp) row col

*Collapse to district level 
collapse_save_labels
collapse (mean) age h365_* [aw=weight], by(nss_state_id nss_district_id urban female)
collapse_apply_labels

merge 1:1 nss_state_id nss_district_id urban female using $tmp/nss75/districtdata, nogen
save $tmp/nss75/districtdata, replace

order nss_state_id nss_district_id urban female age i15_*any i15_* h365_*any h365_*

/* save NSS-identified dataset */
save $tmp/nss75/nss75_dist, replacek


/****************************/
/* Merge to LGD identifiers */
/****************************/

/* nss state-dist is not unique in the key; there was a single split
in jaintia hills from PC11. joinby handles this correctly; about 100
obs don't match, so observation count is lower. jaintia hills split is
a naive split (not weighted) since these are share variables, weights
don't apply. */
convert_ids, from_ids(nss_state_id nss_district_id) to_ids(lgd_state_id lgd_district_id) key($nss/nss-75-health/nss75_lgd_district_key.dta) weight_var(nss_lgd_wt_pop) long(urban female) metadata_urls(https://docs.google.com/spreadsheets/d/e/2PACX-1vRt6Mm6eZFMytf6mVp6tVNKCoe-GlBuwuarRpruJhhsicLaM0A710HWVsnZiP9V2GDDuGp7rmSKyG3x/pub?gid=1900447643&single=true&output=csv)
order lgd*id urban female, first

/* save LGD version */
save $covidpub/nss/nss75_dist, replace

